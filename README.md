# dbt Labs: Experimental Features

This repository includes projects that extend of existing dbt features, experiment with new database features not yet natively supported in dbt, or otherwise demonstrate cool stuff you can do with just Jinja macros in your project—no forks necessary.

In all cases, these are _demo_ projects, not intended as ready-to-use packages. If you want to use code from this repository in your own project, you're more than welcome to clone and install as a [local package](https://docs.getdbt.com/docs/building-a-dbt-project/package-management/#local-packages), or just copy-paste :)

## [BigQuery Incremental Strategies](bq-incrementals)

* These features shipped in dbt v0.16.0! See [changelog](https://github.com/fishtown-analytics/dbt/blob/dev/octavius-catto/CHANGELOG.md#features-4) and [docs](https://docs.getdbt.com/docs/building-a-dbt-project/building-models/bigquery-configs/#merge-behavior-incremental-models)
* The [project here](bq_incrementals) provided the substrate for a [discourse post](https://discourse.getdbt.com/t/981) benchmarking different incremental strategies on BigQuery

## [Materialized views](materialized-views)

This project adds support for `materialized_view` as a new dbt materialization. It includes implementations for Postgres, Redshift, Snowflake, and BigQuery, through a mix of new macros and overrides of built-in dbt macros. See the [project README](materialized-views/README.md) for details. For another take on dbt + materialized views, check out the [dbt-materialize](https://github.com/MaterializeInc/materialize/tree/main/misc/dbt-materialize#dbt-materialize) plugin.

## [Lambda views](lambda-views)
This lab demonstrates a number of options for lambda views, as discussed in this [discourse article](https://discourse.getdbt.com/t/how-to-create-near-real-time-models-with-just-dbt-sql/1457/3). Additional details about the various approaches can be found in at [lambda-views/README.md](lambda-views/README.md).

## [Snapshot testing](snapshot-testing)
This lab demonstrates how to use snapshots to detect dbt model regressions, as discussed in this [discourse article](https://discourse.getdbt.com/t/build-snapshot-based-tests-to-detect-regressions-in-historic-data/1478). Additional details on how to test this code for yourself can be found at [snapshot-testing/README.md](snapshot-testing/README.md).


## [Dynamic data masking on Redshift](dynamic-data-masking-redshift)
This lab demonstrates how to implement dynamic data masking on Redshift.

Check out [this discourse article](https://discourse.getdbt.com/t/how-to-implement-dynamic-data-masking-on-redshift/2043) for more information.

## [Time on Task](business_hours)

This lab demonstrates two strategies for measuring Time on Task. 

Check out [this devhub article](https://docs.getdbt.com/blog/measuring-business-hours-sql-time-on-task) for more information.

## Resources:
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](http://community.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
