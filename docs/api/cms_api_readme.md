
## 📄 MicroCMSプロキシAPI ドキュメント (FastAPI)

このドキュメントは、**FastAPI**で構築された**MicroCMSへのプロキシAPI**（`app.py`）について説明します。このAPIは、クライアントからのリクエストをMicroCMSに安全に転送し、機密性の高いAPIキーをサーバー側で管理します。

リポジトリにある **main.py** は **flask** を使って構築されたもので、機能は全く同じです。こちらを **Cloud Run** にデプロイする場合には、 **Dockerfile** と **requirements.txt** の現在有効になっている部分をコメント化し、コメント化されている部分を復活させたあとにデプロイしてください。

---

### 🚀 概要

* **フレームワーク**: FastAPI
* **目的**: フロントエンドから直接MicroCMSのAPIキーを露出させることなく、コンテンツを取得するためのプロキシ機能を提供します。
* **主な機能**: CORS設定、オリジンヘッダーによるアクセス制御、MicroCMSへの非同期リクエスト転送。

---

### ⚙️ 環境設定と依存関係

#### 1. 必要な環境変数
APIは起動時に以下の環境変数を必要とします。これらは通常、プロジェクトルートの**.envファイル(Cloud runでは環境変数)**から`python-dotenv`によってロードされます。

* `MICROCMS_SERVICE_DOMAIN`: MicroCMSのサービスドメイン。
* `MICROCMS_API_KEY`: MicroCMSにアクセスするためのAPIキー。

> **注**: これらの環境変数が設定されていない場合、APIは起動時に`EnvironmentError`を発生させます。

#### 2. 依存関係
必要なPythonパッケージは`requirements.txt`に記載されています。

* `fastapi`: ウェブフレームワーク。
* `uvicorn[standard]`: 非同期サーバーおよび標準依存パッケージ。
* `httpx`: 非同期HTTPクライアント。
* `python-dotenv`: 環境変数管理。

---

### 🛡️ セキュリティとミドルウェア

このAPIは、セキュリティを強化するために2つの主要なミドルウェアを使用しています。

#### 1. CORS設定 (`CORSMiddleware`)
特定の**オリジン**からのアクセスのみを許可します。

* **許可されたオリジン (`ALLOWED_ORIGINS`)**: `["https://tonytani37.github.io"]`
* **許可されたメソッド**: `GET`のみ
* **機能**: 許可されたフロントエンドからのクロスオリジンリクエストのみが受け入れられます。

#### 2. オリジンヘッダーチェック (`@app.middleware("http")`)
リクエストの`Origin`ヘッダーを明示的にチェックし、許可されていないオリジンからのリクエストに対して**HTTP 403 Forbidden**を返します。

> **エラーメッセージ**: `"Unauthorized access. Invalid or missing Origin header."`

---

### 📡 プロキシエンドポイント

#### エンドポイント: `/api/v1/{endpoint}`

* **HTTPメソッド**: `GET`
* **機能**: クライアントからのGETリクエストを受け取り、対応するMicroCMSのエンドポイントに転送します。
* **`{endpoint}`**: MicroCMSで定義されたコンテンツタイプ（例: `blogs`, `categories`）。

##### 処理の流れ:

1.  **APIキーのチェック**: クライアントがクエリパラメータに`api-key`を含めていた場合、**HTTP 400 Bad Request**エラー（`"API Key is managed on the server side and must not be passed by the client."`）を返します。
2.  **クエリパラメータ転送**: クライアントから渡されたクエリパラメータ（`request.query_params`）をそのままMicroCMSへ転送します。
3.  **MicroCMSへのリクエスト**:
    * 非同期クライアント`httpx.AsyncClient`を使用します。
    * APIキーは`X-MICROCMS-API-KEY`ヘッダーとして自動的に付加されます。
4.  **レスポンス**:
    * MicroCMSからのレスポンスのステータスコードとJSONコンテンツをクライアントにそのまま返します。
    * MicroCMS側でエラーが発生した場合、`httpx.HTTPStatusError`をキャッチし、そのステータスコードとエラーメッセージをクライアントに伝達します。
    * その他の予期せぬエラーは**HTTP 500 Internal Server Error**として処理されます。

---

### 🐳 Dockerfileの構成

アプリケーションは**Docker**コンテナ内で実行されます。

| ステップ | 説明 |
| :--- | :--- |
| **ベースイメージ** | `FROM python:3.11-slim` - Pythonの軽量版を使用。 |
| **依存関係** | `requirements.txt`を先にコピーし、`pip install`を実行して依存関係をインストール。 |
| **コードコピー** | `COPY . /app` - アプリケーションのコードを全てコンテナにコピー。 |
| **コンテナ起動** | `CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8080"]` - Uvicornサーバーを起動します。 |
| **ポート公開** | `EXPOSE 8080` - コンテナの内部ポートを指定。 |
