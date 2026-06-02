terraform {
  # 完美的分布式 Backend 最佳实践：保持配置完全留空
  # 所有具体的 Bucket、Key、Region 均由 GitHub Actions 在 init 时动态注入！
  backend "s3" {}
}