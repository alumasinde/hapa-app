# Hapa App Architecture

## Responsibilities

The Flutter repository owns presentation, device capabilities, local persistence, API consumption, and client-side interaction state.

```text
Screens
  -> State / Controllers
  -> Repositories
  -> API Client / Local Store
```

## API boundary

The app consumes `/v1` API contracts from `hapa-api` and does not contain PHP business logic or backend configuration.

## Shared client utilities

Reusable client components should cover dates, API errors, authentication state, pagination, connectivity, media selection, and local queue handling.

## Multi-photo feeds

Flash media is represented as a list so the UI can support one or multiple photos without changing the Flash model.
