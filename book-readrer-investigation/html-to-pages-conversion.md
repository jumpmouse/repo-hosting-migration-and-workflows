# HTML to Pages Conversion Process

## Overview

The system converts a single HTML book into multiple pages by:
1. Parsing the HTML into DOM nodes
2. Processing each node based on content type
3. Creating virtual pages that fit within the container dimensions
4. Splitting content that exceeds page boundaries

## Key Components

### 1. Initial Setup
- `fetchBook()` - Retrieves HTML and CSS files from backend
- `extractBody()` - Parses HTML string into DOM nodes
- `createDiv()` - Creates temporary containers for measurement

### 2. Main Conversion Flow (`renderPages()`)
```typescript
renderPages() {
  // 1. Initialize variables and reset state
  // 2. Process each book node:
  for (let [index, child] of this.bookNodes.entries()) {
    // 3. Handle different node types
    if (image) this.handleImage();
    else if (chapter) this.handleChapter();
    else this.handleTextNode();
  }
  // 4. Finalize last page
}
```

### 3. Content Type Handlers

#### Text Nodes (`handleTextNode()`)
- Uses `addTagSplitIfTooLarge()` to split text across pages
- Implements binary search to find optimal split points
- Preserves word boundaries when splitting

#### Images (`handleImage()`)
- Handles inline vs block images differently
- Ensures images don't overflow page boundaries
- Creates dedicated pages for large images

#### Chapters (`handleChapter()`)
- Tracks chapter start positions
- Creates chapter index for navigation
- Handles special formatting for chapter titles

## CSS Columns Implementation

The book reader uses CSS multi-column layout for wider screens (≥768px):
- Each "page" is actually a two-column layout simulating an open book
- Column gap is set to 10% of container width
- Content flows automatically between columns

### Known Issues with Columns
1. **Uneven Column Heights**:
   - Columns may have different heights due to content distribution
   - Can cause empty space at bottom of left column
2. **Content Splitting**:
   - The algorithm doesn't account for column breaks when splitting content
   - May result in awkward splits between columns

## Paragraph Splitting and Style Preservation

The `addTagSplitIfTooLarge()` method handles splitting paragraphs across pages:

1. **Splitting Process**:
   - Uses binary search to find optimal split point
   - Adjusts to nearest word boundary
   - Preserves all original styles and classes

2. **Style Preservation**:
   ```typescript
   const newParagraph = paragraph.cloneNode(true) as HTMLElement;
   // Copies all styles and classes
   ```
   - Split paragraphs maintain all original styling (italic, colors, etc.)
   - Adds 'no-indent' class to continuation paragraphs

3. **Edge Cases**:
   - Very long paragraphs may require multiple splits
   - Empty paragraphs are removed automatically
   - Special elements (quotes, lists) maintain formatting

## Example: Quote Splitting
When a styled quote is split:
1. First part keeps original quote styling
2. Continuation paragraph:
   - Inherits all original styles
   - Gets 'no-indent' class added
   - Maintains italic formatting

## Technical Details

### Page Measurement
- Uses hidden divs with identical styling to measure content
- Considers:
  - Container width/height
  - Current font size
  - Column layout (single vs multi-column)

### Content Splitting Algorithm
```typescript
addTagSplitIfTooLarge() {
  // Binary search to find split point
  while (low <= high) {
    // Test if content fits
    // Adjust search range
  }
  // Adjust split to nearest word boundary
}
```

## Performance Considerations
- Minimizes DOM operations
- Uses efficient algorithms for content splitting
- Debounces resize events

## Example Flow
1. Load HTML book
2. Parse into DOM nodes
3. For each node:
   - Measure content
   - Add to current page if fits
   - Split and create new page if needed
4. Store final page collection

## Recommendations for Improvement
1. **Column Balancing**:
   - Consider using `column-fill: balance`
   - Implement custom column break detection
2. **Split Detection**:
   - Add awareness of column boundaries
   - Improve handling of special elements
3. **Visual Indicators**:
   - Add continuation markers for split paragraphs
   - Consider page break hints in content

## See Also
- `html-book-reader.component.ts` for full implementation
- `book-reader.store.ts` for page state management
