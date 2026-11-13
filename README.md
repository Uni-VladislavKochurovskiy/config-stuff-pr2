# gravel - Граф зависимостей Python-пакетов

Практическая работа #2. Язык реализации: [Odin](https://odin-lang.org/)

1. gravel читает настройки из CSV, проверяет их и выводит в формате
   `ключ=значение`
2. ...
3. ...
4. ...
5. ...

## Сборка и запуск

Нужны Odin, GNU Make и Bash. Тестировалось на Fedora 43 и CachyOS 7.3.3-1. Команды выполняются из корня репозитория:

```sh
make build                               # build bin/gravel
make run                                 # run with examples/config.csv
make run CONFIG=examples/test.csv        # run with another configuration
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

Настройки только проверяются и выводятся: сетевых запросов, чтения связей тестового графа и создания SVG нет.

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
