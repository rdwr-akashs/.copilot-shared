---
description: "React coding conventions for frontend apps. Component naming, hooks patterns, co-located tests, MSW for mocking, accessibility-first queries."
applyTo: "**/*.tsx,**/*.ts"
---

# React Conventions

## Component Naming and File Layout

- PascalCase for component names and files
- One component per file (except tiny sub-components used only within the file)
- Tests co-located alongside the component

```
src/
  features/
    items/
      components/
        ItemList.tsx
        ItemList.test.tsx      ← always co-located
        ItemCard.tsx
        ItemCard.test.tsx
      hooks/
        useItems.ts
        useItems.test.ts
      api/
        itemsApi.ts
      pages/
        ItemsPage.tsx
        ItemsPage.test.tsx
      index.ts                 ← barrel export
```

## Component Structure

```tsx
// Named export (not default — easier to rename/import)
export function ItemCard({ item, onSelect }: ItemCardProps) {
  // Hooks at the top
  const [expanded, setExpanded] = useState(false);

  // Handlers grouped
  const handleSelect = useCallback(() => {
    onSelect(item.id);
  }, [item.id, onSelect]);

  // Early returns for loading/error states
  if (!item) return null;

  // Single return with JSX
  return (
    <Card onClick={handleSelect} aria-label={`Item: ${item.name}`}>
      <CardContent>{item.name}</CardContent>
    </Card>
  );
}

// Props type above the component
interface ItemCardProps {
  item: ItemResponse;
  onSelect: (id: string) => void;
}
```

## Hooks Conventions

- Custom hooks: `use` prefix, one responsibility
- Return an object (not a tuple) when returning more than 2 values
- Hooks live in `hooks/` folder, tested in `hooks/<name>.test.ts`

```tsx
// CORRECT
export function useItems(status?: ItemStatus) {
  const { data, isLoading, isError } = useQuery({
    queryKey: ['items', status],
    queryFn: () => itemsApi.list(status),
  });
  return { items: data ?? [], isLoading, isError };
}

// WRONG — doing too many things in one hook
export function useItemsAndCurrentUser() { ... }  // split into two hooks
```

## State Management

- **Component-local state:** `useState`
- **Derived / computed values:** `useMemo` (but don't over-memoize)
- **Server state (API data):** React Query (`@tanstack/react-query`)
- **Global UI state (theme, modals, auth):** Zustand or React Context
- **No Redux** unless the project already uses it

## API Layer

All API calls go through a typed function in `api/`:

```ts
// itemsApi.ts
import { ItemResponse, CreateItemRequest } from '../types/items';

const BASE = '/api/v1/items';

export const itemsApi = {
  list: (status?: string): Promise<ItemResponse[]> =>
    fetch(`${BASE}${status ? `?status=${status}` : ''}`).then(r => r.json()),

  create: (request: CreateItemRequest): Promise<ItemResponse> =>
    fetch(BASE, { method: 'POST', body: JSON.stringify(request),
                  headers: { 'Content-Type': 'application/json' } }).then(r => r.json()),

  getById: (id: string): Promise<ItemResponse> =>
    fetch(`${BASE}/${id}`).then(r => r.json()),
};
```

Never call `fetch` directly inside a component or hook.

## Mocking in Tests

**MSW only.** Never mock `fetch` with `jest.mock`. Never use `jest.mock('axios')`.

```ts
// In the test: override the default handler for a specific scenario
server.use(
  http.get('/api/v1/items', () =>
    HttpResponse.json([{ id: '1', name: 'Alpha' }])
  )
);
```

## Accessibility Conventions

- **Always provide `aria-label`** on interactive elements that don't have visible text labels
- **Use semantic HTML first** (`<button>`, `<nav>`, `<main>`, `<article>`) before `<div>`
- **Query in tests by role/label** — this enforces accessibility from the start

```tsx
// CORRECT — has role and accessible name
<button aria-label="Delete item Alpha" onClick={onDelete}>
  <DeleteIcon />
</button>

// WRONG — icon-only button with no accessible name
<button onClick={onDelete}><DeleteIcon /></button>
```

## RTL Query Priority (Enforced in Tests)

```
getByRole          ← always first choice
getByLabelText     ← for form inputs
getByPlaceholderText
getByText          ← for non-interactive text
getByAltText       ← for images
getByTitle
getByTestId        ← last resort only
```

Never query by CSS class. Never query by HTML tag alone.

## No Snapshot Tests

Snapshot tests for component logic are forbidden. They add noise to diffs, hide real bugs, and are universally updated without review.

**Use explicit assertions instead:**

```tsx
// WRONG
expect(container).toMatchSnapshot();

// CORRECT
expect(screen.getByText('Alpha')).toBeInTheDocument();
expect(screen.getByRole('button', { name: /delete/i })).toBeDisabled();
```

Visual regression testing (Chromatic, Percy) is OK for design system components in a separate pipeline.

## TypeScript Conventions

- **No `any`** — use `unknown` and narrow it
- **Prefer `interface` for object shapes**, `type` for unions and aliases
- **No `!` non-null assertions** — handle `undefined`/`null` explicitly
- **API response types** generated from the OpenAPI spec (see `api-contract-first` skill)

## Forbidden Patterns

- `any` type
- `!` non-null assertion on non-trivial expressions
- Calling `fetch` directly in a component or hook
- `jest.mock('axios')` or `jest.mock('fetch')` — use MSW
- Snapshot tests for business components
- Default exports for named components
- Accessing DOM directly with `document.querySelector` in tests
