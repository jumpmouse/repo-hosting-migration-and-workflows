# Book Reader Keyboard Navigation Guide

## Keyboard Controls

The book reader supports the following keyboard shortcuts for navigation:

| Key | Action |
|-----|--------|
| Arrow Left / Page Up | Go to previous page |
| Arrow Right / Page Down | Go to next page |
| Home | Go to first page |
| End | Go to last page |

## Accessibility Features

- The reader has `role="document"` for screen readers
- Focus is managed properly when navigating between pages
- ARIA attributes are included for screen reader compatibility

## Implementation Guide

### Step 1: Add Required Imports

```typescript
import { HostListener, HostBinding } from '@angular/core';
```

### Step 2: Set Up Host Bindings for Accessibility

Add these properties to your component class:
```typescript
@HostBinding('attr.role') role = 'document';
@HostBinding('attr.tabindex') tabindex = '0';
@HostBinding('attr.aria-label') ariaLabel = 'Book reader';
```

### Step 3: Implement Keyboard Event Handler

Add this method to handle keyboard navigation:
```typescript
@HostListener('keydown', ['$event'])
handleKeyboardEvent(event: KeyboardEvent) {
  switch(event.key) {
    case 'ArrowLeft':
    case 'PageUp':
      // Navigate to previous page
      this.bookReaderStore.previousPage();
      event.preventDefault();
      break;
      
    case 'ArrowRight':
    case 'PageDown':
      // Navigate to next page
      this.bookReaderStore.nextPage();
      event.preventDefault();
      break;
      
    case 'Home':
      // Navigate to first page
      this.bookReaderStore.goToPage(1);
      event.preventDefault();
      break;
      
    case 'End':
      // Navigate to last page
      this.bookReaderStore.goToPage(this.bookReaderStore.totalPages());
      event.preventDefault();
      break;
  }
}
```

### Step 4: Verify Store Methods

Ensure your BookReaderStore has these methods:
- `previousPage()` - Navigates to previous page
- `nextPage()` - Navigates to next page
- `goToPage(number)` - Navigates to specific page
- `totalPages()` - Returns total page count

### Step 5: Testing Checklist

1. Test all keyboard shortcuts:
   - Arrow Left/Right
   - Page Up/Down
   - Home/End
2. Verify focus remains visible
3. Test with screen readers
4. Check mobile responsiveness

## Best Practices

- Document keyboard controls for users
- Ensure focus styles are visible
- Consider adding visual feedback for page turns
- Test with different screen readers

## Complete Example

See the full implementation example in the original documentation file.
