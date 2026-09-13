# Инвентарь — инвентаризация имущества с QR-кодами

Учебное iOS/iPadOS-приложение (вариант 3): иерархия хранения «Комната → Контейнер → Вещь»,
поиск с местоположением, карточка контейнера с программно сгенерированным QR-кодом,
сканирование QR-кода, полный CRUD, экспорт списка вещей коробки и загрузка начальных данных через REST API.

**Стек:** Swift, SwiftUI, MVVM (`@Observable`), SwiftData, Combine, CoreImage, Vision, AVFoundation. Минимальная версия — iOS 17.

## Этапы (теги)

| Тег | Лабораторная работа | Что добавлено |
|-----|---------------------|---------------|
| `lab1` | ЛР 1 — SwiftUI | главный экран с иерархией хранения, поиск с местоположением, навигация |
| `lab2` | ЛР 2 — MVVM | ViewModel и протоколы зависимостей, карточка контейнера, генерация и сканирование QR |
| `lab3` | ЛР 3 — хранение данных | SwiftData, полный CRUD, JSON-классификатор типов `item_types.json` |
| `lab4` | ЛР 4 — REST и Combine | загрузка `db.json` через REST при каждом старте, экспорт коробки в JSON/CSV, debounce-поиск |

## Запуск на Mac

```bash
git clone https://github.com/dezshev/RPiPiP-InventoryQR.git
cd RPiPiP-InventoryQR
git checkout lab4            # или lab1 / lab2 / lab3
brew install xcodegen
xcodegen generate
open InventoryQR.xcodeproj   # схема InventoryQR, симулятор iPhone или iPad → Run
```

В симуляторе камера недоступна, поэтому сканер работает в режиме программного mock:
выбирается снимок наклейки из `InventoryQR/Resources/MockQR`, QR-код распознаётся фреймворком Vision.

## Без Mac

Каждый push запускает GitHub Actions (`.github/workflows/ios.yml`): сборка, модульные и UI-тесты на
симуляторах iPhone и iPad. В артефактах запуска — снимки экранов (`screenshots`), журналы (`logs`)
и собранное приложение для симулятора (`InventoryQR-simulator-app`), которое можно открыть в браузере через Appetize.io.

## Аргументы запуска

| Аргумент | Назначение |
|----------|------------|
| `-uiTesting` | база данных только в памяти |
| `-seedSampleData` | тестовый набор комнат, контейнеров и вещей |
| `-offline` | не обращаться к REST API при старте |
| `-resetStore` | удалить файл базы данных перед запуском |
| `INVENTORY_API_URL` (переменная окружения) | другой адрес REST API |

REST mock-сервер: https://my-json-server.typicode.com/dezshev/RPiPiP-InventoryQR (данные из `db.json`).
