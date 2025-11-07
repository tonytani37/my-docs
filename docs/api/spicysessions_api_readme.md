

# 📚 MongoDB Sessions API 技術ドキュメント

## 1\. 概要 (Overview) 🚀

本APIは、Pythonの**FastAPI**フレームワークと非同期MongoDBドライバー\*\*`motor`\*\*を使用して構築されています。主な目的は、MongoDBデータベースに保存されている「Spicy Sessions」番組のセッション曲情報を取得し、JSON形式でクライアントに提供することです。

| 項目 | 詳細 |
| :--- | :--- |
| **フレームワーク** | FastAPI |
| **データベース** | MongoDB |
| **ドライバー** | `motor` (非同期) |
| **主な機能** | 全セッションデータの取得 |
| **アクセス制限** | CORSによるアクセス制御あり（開発環境では`*`で全許可） |

-----

## 2\. 環境構築と依存関係 (Setup) 🛠️

### 2.1. 必要なライブラリ (`requirements.txt`)

アプリケーションの実行に必要な依存関係は以下の通りです。

```txt
fastapi
uvicorn[standard] # ASGIサーバー
motor             # 非同期MongoDBドライバー
pydantic          # データモデルと検証
python-dotenv     # 環境変数のロード
```

### 2.2. 環境変数 (.env)

MongoDBへの接続情報は、セキュリティのため環境変数として設定する必要があります。

| 変数名 | 説明 |
| :--- | :--- |
| `MONGODB_URI` | MongoDBの接続文字列（URI）。`db.py`で利用されます。 |

### 2.3. 実行コマンド

アプリケーションをローカルで起動するには、Uvicornを使用します。

```bash
uvicorn main:app --reload
```

-----

## 3\. APIエンドポイント (Endpoints) 🎯

| メソッド | パス | 概要 | レスポンスモデル |
| :--- | :--- | :--- | :--- |
| `GET` | `/` | APIの稼働状況（ヘルスチェック）を確認します。 | `{"message": "MongoDB Sessions API is running."}` |
| `GET` | `/songs` | MongoDBに保存されている全てのセッション曲情報を取得します。 | `List[SpicySession]` |

### 3.1. `/songs`エンドポイント

  * **機能**: MongoDBの指定されたコレクションから全てのドキュメントを取得し、Pydanticモデルに基づいてJSONに変換して返します。
  * **レスポンススキーマ**: `models.py`で定義されている`SpicySession`モデルに基づきます。

-----

## 4\. アプリケーションの構成要素 (Architecture) 🏗️

### 4.1. `main.py` (FastAPI Application)

FastAPIの**コアロジック**と**ルーティング**を担います。

  * **ライフサイクル管理**:
      * `@app.on_event("startup")`: アプリケーション起動時に`db.connect_to_mongo()`を呼び出し、DB接続を確立します。
      * `@app.on_event("shutdown")`: アプリケーション終了時に`db.close_mongo_connection()`を呼び出し、DB接続を安全に閉じます。
  * **ミドルウェア**: `CORSMiddleware`を設定し、クロスオリジンリクエストを許可しています（現在の設定は`allow_origins=["*"]`で**全許可**）。
  * **ルーティング**: `/`と`/songs`エンドポイントを定義し、`/songs`では`db.get_all_sessions()`を呼び出します。

### 4.2. `db.py` (Database Layer)

MongoDBへの**接続**と**データアクセス層**を担います。

  * **接続**: `motor.motor_asyncio.AsyncIOMotorClient`を使用し、非同期で接続を行います。
  * **設定**: 接続URI、データベース名 (`spicy_sessions_db`)、コレクション名 (`songs`) を環境変数や定数から取得します。
  * **データ取得関数**: `async def get_all_sessions()`が非同期処理でコレクション全体をスキャンし、`motor`のカーソルから全ドキュメントをリストとして返します。

### 4.3. `models.py` (Pydantic Models)

データの**スキーマ定義**と**検証**を担います。

  * **`SessionInfo`**: セッション曲ごとの詳細情報（`セッション曲`, `オリジナル`, `歌唱`, `演奏者`）を定義します。
  * **`SpicySession`**: メインの放送回情報と、`セッション情報`リスト（`SessionInfo`のリスト）を定義します。
      * **MongoDB対応**: `PyObjectId`カスタム型と`json_encoders = {ObjectId: str}`を設定することで、MongoDBの特殊な`ObjectId`をJSONの文字列形式に**自動変換**し、クライアントが扱いやすい形式に整形します。

-----

## 5\. データスキーマ (Data Schema) 💾

`/songs`エンドポイントで返されるJSONデータの構造（`SpicySession`モデル）は以下の通りです。

```json
[
  {
    "id": "60c0f9b6...", // MongoDBの_id (文字列に変換)
    "回": 1,
    "放送日": "2023年12月16日",
    "放送時間": "土曜日 23:00 - 24:00",
    "放送タイトル": "Spicy Sessions with 平原綾香",
    "カレー": "特製チキンカレー",
    "参考": "　",
    "link": "...",
    "space": "...",
    "セッション情報": [
      {
        "セッション曲": "からっぽのハート",
        "オリジナル": "平原綾香",
        "歌唱": "平原綾香",
        "演奏者": "大貫祐一郎(Piano)"
      }
      // ... 他のセッション曲
    ]
  }
  // ... 他の放送回
]
```