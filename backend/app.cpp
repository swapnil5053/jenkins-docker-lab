#include <arpa/inet.h>
#include <csignal>
#include <cerrno>
#include <cstring>
#include <ctime>
#include <iomanip>
#include <iostream>
#include <netinet/in.h>
#include <sstream>
#include <string>
#include <sys/socket.h>
#include <unistd.h>

static volatile sig_atomic_t keep_running = 1;
static int request_count = 0;

void handle_shutdown(int) {
    keep_running = 0;
}

std::string get_timestamp() {
    std::time_t now = std::time(nullptr);
    std::tm* local_time = std::localtime(&now);
    std::ostringstream timestamp;
    timestamp << std::put_time(local_time, "%Y-%m-%d %H:%M:%S");
    return timestamp.str();
}

std::string extract_request_token(const std::string& request, size_t index) {
    std::istringstream stream(request);
    std::string token;
    for (size_t i = 0; i <= index; ++i) {
        if (!(stream >> token)) {
            return i == 0 ? "GET" : "/";
        }
    }
    return token;
}

std::string extract_request_method(const std::string& request) {
    return extract_request_token(request, 0);
}

std::string extract_request_path(const std::string& request) {
    return extract_request_token(request, 1);
}

std::string build_response_header(const std::string& status_line, size_t content_length) {
    std::ostringstream header;
    header << "HTTP/1.1 " << status_line << "\r\n"
           << "Content-Type: text/plain; charset=utf-8\r\n"
           << "Content-Length: " << content_length << "\r\n"
           << "Server: Lightweight Backend v1.0\r\n"
           << "Connection: close\r\n"
           << "\r\n";
    return header.str();
}

std::string build_status_body(const std::string& hostname) {
    std::ostringstream body;
    body << "====================================\n"
         << " Lightweight Distributed Backend\n"
         << "====================================\n\n"
         << "Served by : " << hostname << "\n"
         << "Timestamp : " << get_timestamp() << "\n"
         << "Request # : " << request_count << "\n"
         << "Status    : Healthy\n"
         << "Version   : 1.0\n\n"
         << "For health check: GET /health\n";
    return body.str();
}

std::string build_health_body() {
    return "OK\n";
}

std::string build_not_found_body(const std::string& path) {
    std::ostringstream body;
    body << "Endpoint not found: " << path << "\n"
         << "Available endpoints: /, /health\n";
    return body.str();
}

void log_request(const std::string& method,
                 const std::string& path,
                 const std::string& client_ip,
                 const std::string& hostname) {
    std::cout << "[" << get_timestamp() << "] "
              << hostname << " -> " << method << " " << path
              << " from " << client_ip
              << " (Request #" << request_count << ")"
              << std::endl;
}

void send_response(int client_fd, const std::string& header, const std::string& body) {
    std::string full_response = header + body;
    send(client_fd, full_response.c_str(), full_response.size(), 0);
}

int main() {
    std::signal(SIGINT, handle_shutdown);
    std::signal(SIGTERM, handle_shutdown);

    char hostname[256];
    if (gethostname(hostname, sizeof(hostname)) != 0) {
        std::strcpy(hostname, "unknown");
    }
    hostname[sizeof(hostname) - 1] = '\0';

    int server_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (server_fd < 0) {
        std::cerr << "[ERROR] Failed to create socket" << std::endl;
        return 1;
    }

    int opt = 1;
    if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt)) < 0) {
        std::cerr << "[ERROR] Failed to set socket options" << std::endl;
        close(server_fd);
        return 1;
    }

    sockaddr_in address{};
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(8080);

    if (bind(server_fd, reinterpret_cast<sockaddr*>(&address), sizeof(address)) < 0) {
        std::cerr << "[ERROR] Failed to bind to port 8080" << std::endl;
        close(server_fd);
        return 1;
    }

    if (listen(server_fd, 10) < 0) {
        std::cerr << "[ERROR] Failed to listen on port 8080" << std::endl;
        close(server_fd);
        return 1;
    }

    std::cout << "===========================================" << std::endl;
    std::cout << "  Lightweight Backend Service Started" << std::endl;
    std::cout << "  Hostname:  " << hostname << std::endl;
    std::cout << "  Port:      8080" << std::endl;
    std::cout << "  Version:   1.0" << std::endl;
    std::cout << "  Status:    ✓ Ready to accept connections" << std::endl;
    std::cout << "===========================================" << std::endl;

    while (keep_running) {
        sockaddr_in client_addr{};
        socklen_t client_addr_len = sizeof(client_addr);

        int client_fd = accept(server_fd, reinterpret_cast<sockaddr*>(&client_addr), &client_addr_len);
        if (client_fd < 0) {
            if (errno == EINTR && !keep_running) {
                break;
            }
            continue;
        }

        request_count++;

        char client_ip[INET_ADDRSTRLEN] = "unknown";
        inet_ntop(AF_INET, &client_addr.sin_addr, client_ip, INET_ADDRSTRLEN);

        char buffer[2048] = {0};
        ssize_t bytes_read = read(client_fd, buffer, sizeof(buffer) - 1);
        if (bytes_read < 0) {
            close(client_fd);
            continue;
        }

        std::string http_request(buffer);
        std::string method = extract_request_method(http_request);
        std::string path = extract_request_path(http_request);
        log_request(method, path, client_ip, hostname);

        std::string body;
        std::string header;

        if (path == "/health") {
            body = build_health_body();
            header = build_response_header("200 OK", body.size());
        } else if (path == "/" || path.empty()) {
            body = build_status_body(hostname);
            header = build_response_header("200 OK", body.size());
        } else {
            body = build_not_found_body(path);
            header = build_response_header("404 Not Found", body.size());
        }

        send_response(client_fd, header, body);
        close(client_fd);
    }

    std::cout << "Shutdown signal received. Closing backend service." << std::endl;
    close(server_fd);
    return 0;
}
