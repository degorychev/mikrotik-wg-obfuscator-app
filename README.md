# WireGuard Obfuscator для MikroTik

Custom App для запуска [WireGuard Obfuscator](https://github.com/ClusterM/wg-obfuscator) рядом со штатным WireGuard-клиентом RouterOS.

Приложение маскирует транспорт WireGuard, при этом сам VPN продолжает обслуживать нативный интерфейс WireGuard в MikroTik:

```text
устройства LAN → таблица vpn → WireGuard RouterOS
→ локальный wg-obfuscator App → интернет
→ wg-obfuscator / wg-obfuscator-easy на сервере
```

## Требования

- RouterOS 7.22 или новее;
- архитектура `arm`, `arm64` или `x86`;
- установленный пакет `container`;
- включённый Container device mode;
- собственный сервер с `wg-obfuscator` или `wg-obfuscator-easy`;
- клиентская конфигурация WireGuard и WireGuard Obfuscator, полученная с сервера.

Первоначальное включение контейнеров требует физического доступа к MikroTik:

```routeros
/system/device-mode/update container=yes
```

Подтвердите изменение кнопкой на устройстве в течение отведённого RouterOS времени. Пакет `container` и device mode включаются только один раз.

## 1. Подготовка Apps

Откройте WebFig → **Apps** и запустите мастер **Setup**. Выберите:

- диск для приложений;
- LAN bridge;
- основной IP роутера.

Мастер автоматически подготовит хранилище, VETH и исходящий NAT для приложений.

## 2. Подключение каталога

Выполните в терминале RouterOS:

```routeros
/app/settings set app-store-urls="https://degorychev.github.io/mikrotik-wg-obfuscator-app/app-store.yml"
```

После обновления списка в Apps появится приложение `wg-obfuscator-client`.

- Страница проекта: <https://degorychev.github.io/mikrotik-wg-obfuscator-app/>
- YAML-каталог: <https://degorychev.github.io/mikrotik-wg-obfuscator-app/app-store.yml>
- Контейнер: `ghcr.io/degorychev/mikrotik-wg-obfuscator-app:latest`

## 3. Настройка приложения

Перед первым запуском откройте настройки `wg-obfuscator-client` и задайте переменные:

| Переменная | Значение |
|---|---|
| `WG_OBF_TARGET` | Публичный адрес и UDP-порт сервера, например `203.0.113.10:51820` |
| `WG_OBF_KEY` | Значение `key` из клиентской конфигурации обфускатора |
| `WG_OBF_SOURCE_PORT` | Локальный UDP-порт, обычно `13255` |
| `WG_OBF_MASKING` | `STUN` рекомендуется для сетей с DPI |
| `WG_OBF_VERBOSE` | `INFO`, для диагностики можно временно поставить `DEBUG` |
| `WG_OBF_IN_TIMEOUT` | `30` секунд для восстановления зависшей UDP-сессии |

Запустите App. В журнале должна появиться информация о прослушивании порта и выбранном сервере:

```routeros
/log print where topics~"container"
```

Не публикуйте `WG_OBF_KEY`. Это не ключ шифрования WireGuard, но он является частью конфигурации маскировки.

## 4. Интеграция со штатным WireGuard

App устанавливает контейнер и его сеть, но намеренно не изменяет WireGuard, firewall и policy routing без явного импорта администратора.

Скачайте шаблон:

<https://degorychev.github.io/mikrotik-wg-obfuscator-app/routeros/install.template.rsc>

В начале файла замените:

```routeros
:local privateKey "CHANGE_ME_CLIENT_PRIVATE_KEY"
:local serverPublicKey "CHANGE_ME_SERVER_PUBLIC_KEY"
:local serverTransportIP "CHANGE_ME_SERVER_IPV4"
```

Значения берутся из клиентского файла, выданного `wg-obfuscator-easy`:

- `privateKey` — `[Interface] PrivateKey`;
- `serverPublicKey` — `[Peer] PublicKey`;
- `serverTransportIP` — публичный IPv4 сервера без порта.

При необходимости скорректируйте:

```routeros
:local sourcePort 13255
:local listenPort 51821
:local tunnelAddress "10.6.13.2/24"
:local tunnelGateway "10.6.13.1"
:local routingTable "vpn"
```

Загрузите изменённый файл на MikroTik и импортируйте:

```routeros
/import install.template.rsc
```

Установщик можно запускать повторно. Он обновляет собственные объекты вместо создания дубликатов:

- интерфейс и peer WireGuard;
- адрес туннеля;
- маршрут по умолчанию в таблице `vpn`;
- исключение серверного IP из policy routing;
- masquerade клиентского трафика в WireGuard.

После успешного импорта удалите `install.template.rsc` с роутера: файл содержит приватный ключ WireGuard.

## 5. Направление трафика в VPN

Установщик создаёт default route в таблице `vpn`, но не решает, какой трафик должен использовать эту таблицу.

Пример маршрутизации списка адресов:

```routeros
/ip firewall mangle add \
    chain=prerouting \
    dst-address-list=VPN \
    action=mark-routing \
    new-routing-mark=vpn
```

Можно использовать уже существующие правила с `new-routing-mark=vpn`. Не маркируйте публичный IP самого VPN-сервера: установщик добавляет отдельное раннее исключение для трафика контейнера.

## Диагностика

Скачайте и импортируйте:

<https://degorychev.github.io/mikrotik-wg-obfuscator-app/routeros/diagnose.rsc>

```routeros
/import diagnose.rsc
```

Скрипт выводит:

- состояние App и его IP;
- endpoint WireGuard;
- время последнего handshake;
- RX/TX peer;
- маршрут таблицы `vpn`;
- счётчики mangle и NAT;
- журнал контейнера.

Для ручной проверки:

```routeros
/interface wireguard peers print detail where name="wg-obf-easy-server"
/ip route print detail where routing-table=vpn
/log print where topics~"container"
```

Если handshake проходит только один раз, а ответы затем пропадают, оставьте `WG_OBF_MASKING=STUN`. Такой режим помог обойти фильтрацию UDP/DPI в протестированной конфигурации.

## Удаление

Скрипт удаления:

<https://degorychev.github.io/mikrotik-wg-obfuscator-app/routeros/uninstall.rsc>

```routeros
/import uninstall.rsc
```

Он удаляет только созданные интеграцией RouterOS-объекты. Сам App и его данные сохраняются. Удалить приложение и его данные можно отдельно через Apps → Cleanup; это необратимая операция.

## Безопасность

- не добавляйте WireGuard private key и `WG_OBF_KEY` в Git;
- удаляйте установочный `.rsc` с роутера после импорта;
- используйте закреплённые версии контейнера для критичных установок;
- помните, что контейнеры расширяют поверхность атаки роутера;
- `wg-obfuscator` скрывает признаки WireGuard, но не заменяет его шифрование.

## Для разработчиков и форков

Workflow [`.github/workflows/publish.yml`](.github/workflows/publish.yml):

- собирает `linux/arm/v7`, `linux/arm64` и `linux/amd64`;
- публикует образ в GHCR;
- подставляет имя владельца и репозитория в YAML-каталог;
- разворачивает каталог и страницу через GitHub Pages.

Для собственного форка включите **Settings → Pages → GitHub Actions** и сделайте опубликованный GHCR package публичным.

Локальная генерация Pages:

```sh
GITHUB_REPOSITORY=example/mikrotik-wg-obfuscator-app \
GITHUB_REPOSITORY_OWNER=example \
sh scripts/render-site.sh
```

Локальная сборка контейнера:

```sh
docker build -t wg-obfuscator-app:dev container
```

Обёртка проекта распространяется по лицензии MIT. Включённый `wg-obfuscator` сохраняет лицензию GPL-3.0-or-later; подробности находятся в [`container/THIRD_PARTY_NOTICES.md`](container/THIRD_PARTY_NOTICES.md).
