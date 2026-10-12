# Bài 2: Tự động hóa đóng gói và phát hành Docker Image khi gắn Git Tag

## Mô tả

Workflow `release.yml` tự động **build** và **push** Docker Image lên **GitHub Container Registry (GHCR)** mỗi khi có Git Tag dạng `v*.*.*` được push lên repository.

---

## Cấu trúc file

```
.github/
└── workflows/
    └── release.yml          # Workflow CD chính
IT209_/SS12/homework/session_12/ex2/
├── Dockerfile               # Dockerfile mẫu cho Spring Boot
└── README.md                # Tài liệu này
```

---

## Luồng hoạt động

```
git tag v1.0.0
git push origin v1.0.0
         │
         ▼
   GitHub Actions kích hoạt release.yml
         │
         ▼
   ┌─────────────────────────────────┐
   │  Job: release-image             │
   │                                 │
   │  1. Checkout mã nguồn           │
   │  2. Đăng nhập GHCR              │
   │  3. Trích xuất metadata/tags    │
   │  4. Setup Docker Buildx         │
   │  5. Build & Push Image          │
   └─────────────────────────────────┘
         │
         ▼
   ghcr.io/<owner>/<repo>:v1.0.0
   ghcr.io/<owner>/<repo>:1.0
   ghcr.io/<owner>/<repo>:1
```

---

## Giải thích các thành phần chính

### 1. Sự kiện kích hoạt (trigger)

```yaml
on:
  push:
    tags:
      - 'v*.*.*'   # Chỉ kích hoạt khi push tag dạng v1.0.0, v2.3.1, ...
```

### 2. Permissions

```yaml
permissions:
  contents: read
  packages: write   # Bắt buộc để push lên GHCR
```

### 3. docker/metadata-action@v5

Action này tự động tạo các Docker tags từ Git tag:

| Git Tag  | Docker Tags được tạo                        |
|----------|---------------------------------------------|
| v1.0.0   | ghcr.io/.../...:1.0.0, :1.0, :1            |
| v2.3.1   | ghcr.io/.../...:2.3.1, :2.3, :2            |

### 4. docker/build-push-action@v5

```yaml
- uses: docker/build-push-action@v5
  with:
    context: .           # Build context là thư mục hiện tại
    push: true           # Tự động push sau khi build xong
    tags: ${{ steps.meta.outputs.tags }}
    cache-from: type=gha  # Cache để build nhanh hơn
    cache-to: type=gha,mode=max
```

---

## Cách kiểm tra

### Gán tag và push lên GitHub:

```bash
# Gán tag phiên bản v1.0.0 tại commit hiện tại
git tag v1.0.0

# Push tag lên GitHub (kích hoạt workflow)
git push origin v1.0.0
```

### Kiểm tra kết quả:

1. Vào tab **Actions** trên GitHub → Thấy workflow `CD - Release Docker Image` đang chạy
2. Sau khi hoàn thành → Vào **Packages** → Thấy image `ghcr.io/<owner>/<repo>:v1.0.0`

---

## Lưu ý

- `GITHUB_TOKEN` được GitHub tự động tạo, **không cần tạo secret thủ công**.
- Image sẽ được đặt ở chế độ **private** mặc định; cần vào Settings → Packages để đặt public nếu cần.
- Cần đảm bảo `Dockerfile` tồn tại ở **root** của repository.
