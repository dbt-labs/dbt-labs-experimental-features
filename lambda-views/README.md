# Lambda views

## Option 1:
Implement this without any macros.

![Option 1 DAG](etc/option-1-dag.png)


Things to note:
- Use of the `run_started_at` [variable](https://docs.getdbt.com/reference/dbt-jinja-functions/run_started_at/)
- We've added some meta fields to make debugging easier

Pros:
- Relatively easy to intuit what's going on

Cons:
- SQL is re-used — two models have the transformation SQL (e.g. `page_views_current` and `page_views_historical`), and the SQL in the models that union together the two relations are very similar
- Very brittle — have to remember to materialize each model appropriately
