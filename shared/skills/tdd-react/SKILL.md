---
name: tdd-react
description: Use when implementing any React component, hook, or page. TDD cycle with React Testing Library, Jest, and MSW. Write tests before components. Red → Green → Refactor.
---

# TDD — React

## Activation Rule

**Triggers:**
- Implementing any new React component, hook, context, or page
- Fixing a UI bug (write a failing test first)
- "Build the [X] component", "Add [X] to the UI", "Fix [X] in React"

> **Override Directive:** NO PRODUCTION REACT CODE WITHOUT A FAILING TEST FIRST.

## The Cycle

```
RED   → Write the test. It fails because the component/hook doesn't exist or doesn't behave correctly.
GREEN → Write the minimum code to make it pass.
REFACTOR → Clean up. Tests still pass.
```

## Test Tool Selection

| What you're testing | Tool |
|---|---|
| Component rendering + interaction | React Testing Library (RTL) |
| Custom hooks | `@testing-library/react` → `renderHook` |
| API calls (mock server) | MSW (Mock Service Worker) |
| State management (Zustand / Redux) | RTL + store integration |
| Routing | `MemoryRouter` wrapper |
| Async data loading | `waitFor`, `findBy*` queries |

## Step-by-Step

### Step 1: Write the failing test

```tsx
// ComponentName.test.tsx — same folder as component
import { render, screen, userEvent } from '@testing-library/react';
import { ItemList } from './ItemList';
import { server } from '../../mocks/server';   // MSW server
import { http, HttpResponse } from 'msw';

describe('ItemList', () => {
  it('shows loading spinner while fetching', () => {
    render(<ItemList />);
    expect(screen.getByRole('progressbar')).toBeInTheDocument();
  });

  it('shows item names after loading', async () => {
    server.use(
      http.get('/api/items', () =>
        HttpResponse.json([{ id: '1', name: 'Alpha' }, { id: '2', name: 'Beta' }])
      )
    );
    render(<ItemList />);
    expect(await screen.findByText('Alpha')).toBeInTheDocument();
    expect(screen.getByText('Beta')).toBeInTheDocument();
  });

  it('shows error message when API fails', async () => {
    server.use(
      http.get('/api/items', () => HttpResponse.error())
    );
    render(<ItemList />);
    expect(await screen.findByRole('alert')).toHaveTextContent(/failed to load/i);
  });
});
```

### Step 2: Run and confirm RED

```bash
npx jest --watch ItemList.test.tsx
```

Test fails with "cannot find module" or "element not found" — not a test syntax error.

### Step 3: Write minimum component code

```tsx
// ItemList.tsx
export function ItemList() {
  const { data, isLoading, isError } = useItems();

  if (isLoading) return <CircularProgress role="progressbar" />;
  if (isError) return <Alert severity="error" role="alert">Failed to load items</Alert>;

  return (
    <ul>
      {data?.map(item => <li key={item.id}>{item.name}</li>)}
    </ul>
  );
}
```

### Step 4: Confirm GREEN, then refactor

---

## Custom Hook Test Pattern

```tsx
// useItems.test.ts
import { renderHook, waitFor } from '@testing-library/react';
import { useItems } from './useItems';
import { QueryClientWrapper } from '../../test-utils/QueryClientWrapper';

describe('useItems', () => {
  it('fetches and returns items', async () => {
    const { result } = renderHook(() => useItems(), {
      wrapper: QueryClientWrapper,   // wraps with React Query client
    });

    expect(result.current.isLoading).toBe(true);

    await waitFor(() => {
      expect(result.current.isLoading).toBe(false);
    });

    expect(result.current.data).toHaveLength(2);
  });
});
```

## MSW Setup Pattern

```ts
// src/mocks/handlers.ts
import { http, HttpResponse } from 'msw';

export const handlers = [
  http.get('/api/items', () =>
    HttpResponse.json([
      { id: '1', name: 'Default Item 1' },
      { id: '2', name: 'Default Item 2' },
    ])
  ),
];

// src/mocks/server.ts  (Node — for tests)
import { setupServer } from 'msw/node';
import { handlers } from './handlers';
export const server = setupServer(...handlers);

// src/mocks/browser.ts  (Browser — for dev)
import { setupWorker } from 'msw/browser';
import { handlers } from './handlers';
export const worker = setupWorker(...handlers);
```

## Query Priority (RTL — most to least preferred)

```
getByRole > getByLabelText > getByPlaceholderText > getByText
getByDisplayValue > getByAltText > getByTitle > getByTestId
```

Never use `getByTestId` unless none of the above work. Never query by CSS class.

## Async Assertions

```tsx
// Waiting for element to appear
expect(await screen.findByText('Loaded')).toBeInTheDocument();

// Waiting for something to disappear
await waitFor(() => expect(screen.queryByRole('progressbar')).not.toBeInTheDocument());

// Never use waitFor around findBy* — they're already async
```

## User Interaction Pattern

```tsx
import userEvent from '@testing-library/user-event';

it('submits form with valid data', async () => {
  const user = userEvent.setup();
  render(<CreateItemForm onSuccess={vi.fn()} />);

  await user.type(screen.getByLabelText(/name/i), 'New Item');
  await user.selectOptions(screen.getByLabelText(/type/i), 'ACTIVE');
  await user.click(screen.getByRole('button', { name: /create/i }));

  expect(await screen.findByText(/created successfully/i)).toBeInTheDocument();
});
```

## Hard Rules

- **Never test implementation details** (component state, internal methods). Test behaviour from the user's perspective.
- **Queries target accessibility attributes** (role, label) — not CSS classes or test IDs.
- **Test all states:** loading, success, empty, error. Don't only test the happy path.
- **No snapshot tests** for logic — use explicit assertions. Snapshots are only for visual regression in specific pipelines.
- **MSW handles all API mocking.** Never `jest.mock` a fetch/axios module directly.
- **`userEvent` over `fireEvent`** — `userEvent` simulates real browser behaviour.

## Component File Layout

```
src/
  features/
    items/
      components/
        ItemList.tsx
        ItemList.test.tsx       ← co-located test
        ItemCard.tsx
        ItemCard.test.tsx
      hooks/
        useItems.ts
        useItems.test.ts
      api/
        itemsApi.ts
        itemsApi.test.ts
```

## Run Tests

```bash
npx jest --watch                    # all tests, watch mode
npx jest --watch ItemList           # filter by name
npx jest --coverage                 # with coverage report
npx jest --testPathPattern=features # filter by path
```
