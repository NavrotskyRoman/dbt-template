# dbt-template

Шаблон нового dbt-проекта платформы. Клонируйте этот репозиторий и замените имя проекта на свой домен (например `payments`).

## Пошаговая настройка нового проекта

1. **Создайте рабочий каталог проекта и свой репозиторий**  
   - Скопируйте содержимое этого шаблона в новый каталог (например `dbt-payments`).  
   - Создайте **свой** репозиторий на GitHub (например `dbt-payments_nt`) и привяжите его к локальной копии:  
     ```bash
     git init                            # если ещё не инициализировано
     git remote remove origin 2>/dev/null || true
     git remote add origin git@github.com:ВАШ_АККАУНТ/ВАШ_РЕПОЗИТОРИЙ.git
     git add .
     git commit -m "Initial commit"
     git push -u origin main
     ```

2. **Сконфигурируйте `dbt_project.yml`**  
   - Скопируйте `dbt_project.yml.example` в `dbt_project.yml`.  
   - Замените `project_name` на имя домена во всех местах:
     - `name: 'project_name'` → `name: 'payments'`
     - `profile: 'project_name'` → `profile: 'payments'`
     - Секция `models.project_name` → `models.payments`.

3. **Переименуйте папки `project_name` в структурах моделей/тестов**  
   В шаблоне заранее созданы универсальные каталоги с плейсхолдером `project_name`, чтобы показать разбиение по домену:
   - `models/staging/project_name/`
   - `models/intermediate/project_name/`
   - `models/marts/core/`
   - `models/utils/project_name/`
   - `seeds/project_name/`
   - `snapshots/project_name/`
   - `tests/marts/project_name/`

   После выбора домена (например `payments`):
   - переименуйте папки `project_name` в `payments`;
   - складывайте модели/сиды/снапшоты/тесты по методологии (staging/intermediate/marts/utils, домен в имени модели).

4. **Настройте окружение (.env)**  
   - Скопируйте `.env.example` в `.env`.  
   - Заполните переменные:
     - `DBT_BIGQUERY_PROJECT`, `DBT_BIGQUERY_DATASET`, `DBT_BIGQUERY_LOCATION` и т.п. под ваш GCP‑проект.
     - `DBT_ENV_SECRET_BIGQUERY_KEYFILE_JSON` — JSON содержимым service account (не коммитьте реальное значение в git).
   - Локально можно использовать `direnv`, `source .env` или настройки IDE, в Docker/Airflow — передавать эти переменные через env/секреты.

5. **Создайте `profiles.yml` в корне проекта**  
   - Скопируйте `profiles.yml.example` в `profiles.yml`.  
   - Убедитесь, что корневой ключ профиля совпадает с `profile` из `dbt_project.yml` (например `payments:`).  
   - Внутри уже используются `env_var(...)` и метод `service-account-json` с `keyfile_json`, так что никаких локальных `secret.json` не требуется.

6. **Проверьте `packages.yml` и установите зависимости**  
   - В `packages.yml` укажите реальный URL репозитория **dbt-core** (если он приватный/внутренний).  
   - Убедитесь, что версия `dbt_external_tables` вас устраивает.  
   - Выполните:
     ```bash
     dbt deps
     ```

7. **Проверьте методологию слоёв и нейминга**  
   Слои и нейминг описаны в `.cursor/rules/dbt.md`. Кратко: `raws → staging → intermediate → marts`; один датасет на слой в BigQuery, домен в имени модели (кроме marts), префиксы `raw_`, `base_`, `stg_`, `int_`, `fct_`, `dim_` и т.д.

8. **(Опционально) Синхронизируйте правила Cursor из dbt-core**  
   Если вы используете общий пакет `dbt-core` как источник методологии, можно подтянуть актуальную версию правил в `.cursor/rules` проекта скриптом:
   ```bash
   ./scripts/cursor/sync_cursor_rules.sh
   ```
   Скрипт выполнит `dbt deps` и скопирует файл `dbt_packages/dbt_core/.cursor/rules/dbt.md` в `.cursor/rules/dbt.md` проекта.

9. **Первый запуск**  
   - Для быстрой проверки соединения и конфигурации:
     ```bash
     dbt debug
     ```
   - Для базового прогона:
     ```bash
     dbt deps
     dbt seed   # если есть сиды
     dbt run
     dbt test
     ```

## Структура

- `models/raws/` — только YAML с sources (и при необходимости external)
- `models/staging/` — base_ и stg_ по домену
- `models/intermediate/` — int_ по домену
- `models/marts/` — fct_ / dim_, датасеты с доменом (marts_*)
- `models/utils/` — util_ по домену/назначению
- `seeds/` — CSV по домену
- `snapshots/` — при необходимости
- `macros/` — макросы, специфичные для проекта (общие — из пакета dbt-core)
- `tests/` — assertion-тесты по домену

## Запуск моделей с кастомными макросами (dbt-core)

Макросы из пакета **dbt-core** подключаются через `packages.yml` и используются автоматически.

### Что срабатывает при запуске

- **При каждом `dbt run` и `dbt build`** в `dbt_project.yml` заданы хуки:
  - **on-run-start** → вызывается `pipeline_on_run_start()` — при необходимости создаёт/обновляет external-таблицы (по `vars.external_tables` и режиму).
  - **on-run-end** → вызывается `pipeline_on_run_end()` — при необходимости дропает устаревшие таблицы (`vars.deprecated_tables`) и датасеты (`vars.drop_datasets`).

- **При сборке любой модели** dbt использует макрос **`generate_schema_name`** из dbt-core для формирования имени схемы (датасета в BigQuery). Переопределять его в проекте не нужно, если устраивает поведение по умолчанию.

### Режим пайплайна (`pipeline_mode`)

В шаблоне по умолчанию задано `pipeline_mode: "dev"`: external-таблицы не создаются, дропы не выполняются — удобно для локальной разработки и `dbt compile` без доступа к BigQuery.

Для полного пайплайна (CI/Airflow) передавайте режим через `--vars`:

| Режим | Поведение |
|-------|-----------|
| `dev` | Ничего не создаём и не дропаем (по умолчанию в шаблоне). |
| `full` | Создаём external-таблицы из `vars.external_tables`, после run дропаем deprecated и датасеты из списков. |
| `no_external` | External не трогаем, дропы выполняем. |
| `external_only` | Только создаём external по `vars.external_tables`, дропы как в full. |
| `external_all` | Создаём/обновляем все external-таблицы (без select), дропы как в full. |
| `no_drops` | Создаём external по списку, дропы не выполняем. |

Переопределение через переменную окружения (приоритет над `vars`):

```bash
export DBT_PIPELINE_MODE=dev
dbt run
```

### Примеры команд

```bash
# Локальная разработка (макросы вызываются, но external/дропы отключены)
dbt run
dbt build

# Полный пайплайн (CI/Airflow): external + дропы
dbt run --vars '{"pipeline_mode": "full"}'
dbt build --vars '{"pipeline_mode": "full"}'

# Только обновить указанные external-таблицы, затем run и дропы
dbt run --vars '{"pipeline_mode": "external_only", "external_tables": ["raw_mydomain.my_external_table"]}'

# Compile без обращения к BigQuery (хуки в dev ничего не делают)
dbt compile --vars '{"pipeline_mode": "dev"}'
```

### Ручной вызов макросов пайплайна

При необходимости можно вызвать макросы из dbt-core вручную:

```bash
# Удалить таблицы из vars.deprecated_tables (или передать список через --vars)
dbt run-operation drop_deprecated_tables

# Удалить датасет по имени
dbt run-operation drop_datasets --args '{"dataset_name": "no_schema"}'
```

## Команды

```bash
dbt deps
dbt seed
dbt run
dbt test
```

Для CI с Slim: `dbt build --select state:modified+ --defer --state prod_artifacts`.

## License

License: MIT. See [LICENSE](LICENSE).
