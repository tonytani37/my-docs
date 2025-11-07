# Dockerfile.dev — development image for mkdocs with livereload
FROM python:3.11-slim

# 必要パッケージのインストール（軽量）
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

#これを忘れるとmkdocs.ymlがないといってサービスが起動しないので注意
COPY . .

# pip のアップグレードと mkdocs インストール（必要ならプラグインも追加）
RUN pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir mkdocs mkdocs-material

# 作業ディレクトリをマウントして使うのでファイルはコンテナにコピーしない
EXPOSE 8000

# mkdocs.yml はワークスペースのルートに、ドキュメントは docs/ に置く想定
# ホスト側でマウントして使う:
# docker run -v $(pwd):/workspace -p 8000:8000 ...
CMD ["mkdocs", "serve", "-a", "0.0.0.0:8000", "--livereload"]
