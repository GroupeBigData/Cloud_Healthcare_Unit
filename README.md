# Cloud_Healthcare_Unit

This project aims to help a hospital group better understand its activity through data analysis. It brings together information from several sources, including patient records, hospital reference data, patient satisfaction surveys, and INSEE death records.

The goal is to combine these datasets into a reliable, well-organised data warehouse that can be used to analyse hospital activity, identify trends, and support decision-making. Particular attention is given to data quality, patient privacy, and compliance with GDPR requirements.

## Goal
Build a unified analytical platform that:

- Integrates four data sources: PostgreSQL, CSV files, FTP satisfaction data, and INSEE death records.
- Improves data quality through validation, cleaning, and consistency checks.
- Limits the use of personal data to what is necessary.
- Organises data for analysis, with a potential Bronze/Silver/Gold architecture and a Kimball star schema.
- Provides dashboards to support healthcare professionals and hospital management.

## Environment under evaluation
Two possible stacks:

| Option | Stack |
|---|---|
| **A** | PostgreSQL + Python/SQL ETL + Power BI |
| **B — Original** | VirtualBox + Cloudera CDH 5.13 + Talend 7.3.1 + JDK/JRE 8 + PostgreSQL 14.2 + Power BI |

## Status
Discovery and analysis phase, no implementation has started yet.
