# =============================================================
# Dockerfile - Spring Boot Application
# Sử dụng multi-stage build để giảm kích thước image cuối
# =============================================================

# Stage 1: Build
FROM eclipse-temurin:17-jdk-alpine AS builder
WORKDIR /app

# Copy Gradle wrapper và dependency files trước (tận dụng Docker cache)
COPY gradlew .
COPY gradle/ gradle/
COPY build.gradle .
COPY settings.gradle .

# Cấp quyền thực thi và tải dependencies
RUN chmod +x gradlew && ./gradlew dependencies --no-daemon

# Copy toàn bộ mã nguồn và build
COPY src/ src/
RUN ./gradlew bootJar --no-daemon -x test

# Stage 2: Runtime (image nhẹ hơn)
FROM eclipse-temurin:17-jre-alpine AS runtime
WORKDIR /app

# Metadata labels (OCI chuẩn)
LABEL org.opencontainers.image.source="https://github.com/phamvietquan/PTIT_CNTT1_IT211_CourseManagementSystem"
LABEL org.opencontainers.image.description="Course Management System - Spring Boot"
LABEL org.opencontainers.image.licenses="MIT"

# Tạo user không phải root để tăng bảo mật
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy JAR từ build stage
COPY --from=builder /app/build/libs/*.jar app.jar

# Chuyển sang user không phải root
USER appuser

# Expose port ứng dụng
EXPOSE 8080

# Khởi chạy ứng dụng
ENTRYPOINT ["java", "-jar", "app.jar"]
