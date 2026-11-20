# gravel - Граф зависимостей Python-пакетов

Практическая работа #2, вариант 14. Язык: [Odin](https://odin-lang.org/).

gravel читает настройки из CSV, получает зависимости из PyPI JSON API,
строит граф итеративным DFS и сохраняет DOT и SVG. По настройке выводит
ASCII-дерево. Есть тестовый репозиторий и отдельная сборка обратного поиска.
Ошибки выводятся в stderr, код завершения - 1.

## Сборка и запуск

Нужны Odin, GNU Make, Bash, curl и Graphviz (`dot`). Для тестов нужен Python 3.
Проверено с Odin `dev-2026-10-nightly:84bc3fc`. Команды - из корня репозитория.

```sh
make build                               # bin/gravel
make run                                 # examples/config.csv
make run CONFIG=examples/test.csv         # test graph
make reverse CONFIG=examples/test.csv     # reverse dependencies
make check                               # check source code
make test                                # offline Odin and CLI tests
make demo-errors                         # errors for all six settings
make demo-graphs                         # diamond, cycle, self-loop, isolated node, filter
make demo-reverse                        # reverse dependency examples
make demo-packages                       # three PyPI packages; requires network
make compare                             # compare with pipdeptree; requires network
make clean                               # remove bin
```

Прямой запуск: `./bin/gravel examples/config.csv`. Справка: `./bin/gravel --help`.
Компилятор можно задать через `ODIN=/путь/к/odin`.

## Конфигурация

CSV без заголовка: ключ и значение через запятую. Все шесть ключей обязательны.
Неизвестные и повторные ключи считаются ошибкой. Пути - относительно текущего каталога.

| Ключ          | Значение                                                                 |
| ------------- | ------------------------------------------------------------------------ |
| `package`     | Имя Python-пакета; в тестовом режиме - буквы `A`-`Z`                     |
| `repository`  | HTTP(S) адрес PyPI-совместимого JSON API или путь к тестовому графу      |
| `test_mode`   | `true` или `false`                                                       |
| `output_file` | Путь к SVG в существующем каталоге; рядом сохраняется одноимённый `.dot` |
| `ascii_tree`  | Вывод ASCII-дерева: `true` или `false`                                   |
| `filter`      | Подстрока исключаемых имён; пустое значение отключает фильтр             |

```csv
package,python-dateutil
repository,https://pypi.org
test_mode,false
output_file,bin/dependencies.svg
ascii_tree,false
filter,
```

Источник должен предоставлять `/pypi/<имя>/json`. curl только скачивает данные;
метаданные и записи `Requires-Dist` разбирает код Odin. Менеджеры пакетов и
библиотеки анализа зависимостей в gravel не используются.

Граф объединяет все объявленные зависимости последних версий, включая extras
и условия платформы. Ограничения версий и условия установки не вычисляются;
прямые ссылки в требованиях представлены именем пакета из выбранного репозитория.
Это граф объявлений, а не результат разрешения зависимостей pip. У пакетов
с многочисленными extras граф может включать инструменты разработки и их зависимости.

Имена PyPI приводятся к нижнему регистру, последовательности `-`, `_`, `.` - к `-`.
Так же нормализуется фильтр. Тестовые имена и фильтр чувствительны к регистру.
Исключённый узел не загружается, обход через него не продолжается.
При исключении корня сохраняется пустой граф.

## Тестовый граф и обратный поиск

В файле репозитория каждая строка задаёт ребро `A,B`: A зависит от B.
`A,` задаёт узел без зависимостей. Концы рёбер создаются автоматически,
повторные рёбра объединяются. Образцы находятся в `examples/graphs`.

DFS использует стек и посещённые узлы. Циклы и общие зависимости сохраняются
в DOT. В дереве они отмечаются `[cycle]` и `[shared]` без повторного раскрытия.

`make reverse` собирает `bin/gravel-reverse` и выводит прямых и транзитивных
потребителей заданного пакета, по одному имени на строку. Пакет не включается
в собственный список даже при цикле. Нет потребителей - вывод пуст.

Для тестового репозитория обратный поиск охватывает весь файл. Для PyPI - только
граф, достижимый из исходного пакета: JSON API не даёт глобального списка
потребителей. Для полного обратного поиска нужен файл графа. Рёбра разворачиваются,
после чего используется тот же DFS и фильтр. SVG в этом режиме не создаётся.

## Примеры и сравнение

`make demo-packages` создаёт `bin/python-dateutil.svg`, `bin/typing-inspection.svg`
и `bin/click.svg`, соответствующие DOT и выводит деревья.

Сравнение выполнено 21.11.2026: Linux, Python 3.14.7, pipdeptree 4.2.15.

| Пакет                   | gravel                                 | pipdeptree                             |
| ----------------------- | -------------------------------------- | -------------------------------------- |
| python-dateutil 4.0.0   | python-dateutil -> tzdata              | python-dateutil -> tzdata              |
| typing-inspection 0.4.5 | typing-inspection -> typing-extensions | typing-inspection -> typing-extensions |
| click 8.5.1             | Отдельный узел                         | Отдельный узел                         |

Для этих примеров наборы узлов и рёбер совпали. В общем случае gravel включает
условные и необязательные зависимости, а pipdeptree показывает установленные
зависимости выбранного окружения. Также могут различаться версии пакетов.

`make compare` создаёт отдельное окружение в `.zed/comparison-env`, устанавливает
версии из таблицы и запускает оба инструмента. Текстовые результаты и SVG
pipdeptree сохраняются в `.zed`. Это отдельная проверка, не часть анализа gravel.
PyPI обновляется, поэтому повторный запуск gravel может показать новые версии.

## Код

| Модуль                   | Функции                                                                                                                                          |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `src/main.odin`          | `main`: аргументы, загрузка настроек, выбор режима, вывод                                                                                        |
| `src/config`             | `load`, `parse`, `validate`: чтение и проверка CSV; `valid_package`, `valid_url`, `is_alnum`: проверки значений                                  |
| `src/repository`         | `fetch`: HTTP; `parse_metadata`: JSON; `parse_requirement`: имя зависимости; `normalize`: нормализация имён                                      |
| `src/graph/graph.odin`   | `parse`, `load`: тестовый граф; `get_node`: соседи; `traverse`: DFS; `build`: источник; `excluded`: фильтр; `append_unique`: устранение повторов |
| `src/graph/reverse.odin` | `reverse`: разворот рёбер и DFS; `build_reverse`: область обратного поиска                                                                       |
| `src/visualization`      | `quote`: экранирование DOT; `to_dot`, `to_ascii`: представления графа; `save`: запись DOT и SVG через Graphviz                                   |

Тесты находятся в `tests`, конфигурации - в `examples`. Каждый модуль возвращает
свой `Error`; тексты ошибок заданы в `ERROR_STRING`.

История содержит пять коммитов по этапам. Вывод настроек относится к первому,
вывод прямых зависимостей - ко второму. Они доступны в соответствующих коммитах.

Форматы: [PyPI JSON API](https://docs.pypi.org/api/json/),
[Requires-Dist](https://packaging.python.org/en/latest/specifications/core-metadata/#requires-dist-multiple-use),
[Graphviz](https://graphviz.org/doc/info/command.html),
[pipdeptree](https://github.com/tox-dev/pipdeptree).
