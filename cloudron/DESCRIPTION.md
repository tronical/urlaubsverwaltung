## Overview

Urlaubsverwaltung is an open-source web application for managing vacation
and absence requests within a team or company. It provides:

- Self-service vacation requests with multi-step approval workflows
- Departments, teams and per-person work-time and holiday-entitlement settings
- Sick-leave tracking with optional medical-certificate uploads
- Calendar overview, ICS feeds and CalDAV-style calendar sharing
- Email notifications for applicants, approvers and Office staff
- A REST API for integrations and reporting

## On Cloudron

This package wires Urlaubsverwaltung up to Cloudron's built-in services:

- **PostgreSQL** is provisioned automatically and used for all application data.
- **Single Sign-On** is handled through Cloudron's OIDC provider — the first
  user to log in is promoted to the `Office` role and can manage further
  permissions from inside the app.
- **Email** notifications are sent through Cloudron's SMTP relay.
- **Backups** of the database and `/app/data` are taken by Cloudron on the
  schedule you configure in the dashboard.
