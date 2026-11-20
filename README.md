# gravel - Граф зависимостей Python-пакетов

Практическая работа #2. Язык реализации: [Odin](https://odin-lang.org/)

gravel получает прямые зависимости Python-пакета из метаданных PyPI JSON API.
Настройки читаются из CSV. Ошибки выводятся в stderr, код завершения - 1.

## Сборка и запуск

Нужны Odin, GNU Make, Bash и curl. Для тестов нужен Python 3. Тестировалось на Fedora 43 и CachyOS 7.3.3-1. Команды выполняются из корня репозитория:

```sh
make build                               # build bin/gravel
make run                                 # run with examples/config.csv
make check                               # check source code
make test                                # configuration and CLI tests
make demo-errors                         # validation error examples
make clean                               # remove bin
```

Можно запустить напрямую:

```sh
./bin/gravel examples/config.csv
./bin/gravel --help
```

## Конфигурация

CSV без заголовка. В каждой строке ключ и значение через запятую. Все шесть ключей обязательны. Неизвестные и повторные ключи считаются ошибкой. Относительные пути отсчитываются от текущего каталога.

| Ключ          | Значение                                                    |
| ------------- | ----------------------------------------------------------- |
| `package`     | Имя Python-пакета, в тестовом режиме - только буквы `A`-`Z` |
| `repository`  | HTTP(S) URL или путь к читаемому файлу в тестовом режиме    |
| `test_mode`   | Тестовый режим: `true` или `false`                          |
| `output_file` | Путь к `.svg` в существующем каталоге                       |
| `ascii_tree`  | Настройка ASCII-дерева: `true` или `false`                  |
| `filter`      | Подстрока имени пакета, пустое значение отключает фильтр    |

Пример `examples/config.csv`:

```csv
package,requests
repository,https://pypi.org
test_mode,false
output_file,bin/dependencies.svg
ascii_tree,false
filter,
```

Источник должен предоставлять `/pypi/<имя>/json`, как `https://pypi.org`.
Выводятся все записи `Requires-Dist`, включая условия и extras.
Тестовый режим на этом этапе не используется.

## Код

В `src/main.odin` функция `main` обрабатывает запуск, справку и вывод. В `src/config/config.odin` структура `Config` хранит настройки, а функции:

- `load` читает файл
- `parse` разбирает CSV
- `validate` проверяет значения настроек
- `valid_package` и `valid_url` проверяют имя пакета и URL
- `is_alnum` проверяет, является ли символ ASCII-буквой или цифрой

Тесты находятся в `tests`, примеры конфигураций - в `examples`.

Ошибки представлены типом `Error`, сообщения для CLI - мапой `ERROR_STRING`
в `src/config/errors.odin`.

В `src/repository/repository.odin`: `fetch` скачивает метаданные через curl,
`parse_metadata` разбирает JSON, `parse_requirement` извлекает имя зависимости,
`normalize` приводит имена пакетов к каноническому виду.

Форматы: [PyPI JSON API](https://docs.pypi.org/api/json/),
[Requires-Dist](https://packaging.python.org/en/latest/specifications/core-metadata/#requires-dist-multiple-use).
