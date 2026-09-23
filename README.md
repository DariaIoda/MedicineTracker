# Аптечка (MedicineTracker) — контроль медикаментов и сроков годности

Учебное iOS/iPadOS-приложение (вариант 11): плоский список лекарств с сортировкой по сроку годности,
фильтрация по форме выпуска, карточка препарата, автоматизированное добавление через сканирование
текста с упаковки (OCR), проверка конфликтов лекарственных взаимодействий и полный CRUD.

**Стек:** Swift, SwiftUI, MVVM (`@Observable`), SwiftData, Combine, Vision. Минимальная версия — iOS 17.

## Этапы (теги)

| Тег | Лабораторная работа | Что добавлено |
|-----|---------------------|---------------|
| `lab1` | ЛР 1 — SwiftUI | главный экран со списком лекарств, фильтрация по форме выпуска, навигация, карточка препарата |
| `lab2` | ЛР 2 — MVVM | архитектура приложения, логика ScannerViewModel, распознавание текста (Vision OCR) |
| `lab3` | ЛР 3 — хранение данных | SwiftData, полный CRUD, JSON-матрица несовместимости веществ `interactions.json` |
| `lab4` | ЛР 4 — Combine | реактивная обработка потока данных сканера, debounce-поиск конфликтов, вывод Alert |

## Запуск на Mac

```bash
git clone [https://github.com/DariaIoda/MedicineTracker.git](https://github.com/DariaIoda/MedicineTracker.git)
cd MedicineTracker
git checkout lab4            # или lab1 / lab2 / lab3
brew install xcodegen
xcodegen generate
open MedicineTracker.xcodeproj   # схема MedicineTracker, симулятор iPhone или iPad → Run