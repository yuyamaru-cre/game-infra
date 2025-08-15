# Game Infra

## 目的

- Valheim (BepInEx5 固定) と 7 Days to Die を Docker で再現性高く運用
- データは ./valheim/data, ./7d2d/data に永続化
- Discord ボット (別リポジトリ)

## 使い方(最短)

cd compose
docker compose build
docker compose up -d
docker compose ps
docker logs -f valheim
docker logs -f seven-days

## 更新例

# Valheim の BepInEx バージョン変更

vim ../valheim/image/Dockerfile (ARG BEPINEX_VERSION= を変更)
docker compose build valheim
docker compose up -d valheim

## ディレクトリ説明

valheim/data/
worlds/ : ワールド (.db .fwl)
BepInEx/ : config / plugins
logs/ : valheim.log
backups/ : 手動/自動バックアップ
7d2d/data/
saves/ : セーブ
generated/ : serverconfig.xml (テンプレートから生成)
logs/ : latest.log 他
backups/

## バックアップ例

tar czf valheim/data/backups/manual-$(date +%Y%m%d).tgz -C valheim/data worlds BepInEx/config
tar czf 7d2d/data/backups/manual-$(date +%Y%m%d).tgz -C 7d2d/data saves generated/serverconfig.xml

## Rollback

git checkout <過去 commit>
docker compose build
docker compose up -d
