# uptime

Nodante sunucusunu dışarıdan izler. GitHub Actions 10 dakikada bir `hosts.txt`'teki adreslere HTTPS isteği atar;
bir adres 3 denemede de yanıt vermezse Telegram'a "düştü", geri gelince "düzeldi" yazar.

Sunucunun içindeki izleme (Sentinel) sunucu tümden düşünce susar; bu repo o durumu yakalamak için var.
Kayıt: `nodantecom/hq` → `ops/RECOVERY.md`.
