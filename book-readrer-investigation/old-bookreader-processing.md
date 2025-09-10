# Old Book Reader HTML Processing

## Overview

The old book reader (`LOT_Old_Bookreader`) processes HTML content through:
1. Initial parsing and DOM preparation
2. Content measurement and pagination
3. Special element handling (images, chapters)
4. Final page assembly

## Core Processing Flow

### 1. Initial Setup (`process()` method)
```javascript
async process(book, target) {
  // 1. Initialize containers and styles
  // 2. Process HTML content
  // 3. Handle fonts and media
  // 4. Prepare for pagination
}
```

### 2. Pagination Algorithm (`parse()` method)
- Uses virtual containers for measurement
- Processes content node-by-node
- Handles different content types:
  - Text nodes
  - Images (floating/cover/regular)
  - Chapter markers
  - Background elements

### 3. Text Handling
- **Word Wrapping**: Uses `wrapWords()`/`unwrapWords()`
- **Splitting**: Binary search for optimal break points
- **Style Preservation**: Maintains original formatting

### 4. Image Handling
- **Types**:
  - Floating images (positioned with text)
  - Cover images (full page)
  - Regular images (block elements)
- **Quality Levels**: Multiple profiles (HQ, MQ, LQ)

## Key Features

### Font Management
- Dynamic font loading
- Size adjustment based on container
- Multiple font families supported

### Font Handling Implementation

The old reader processes fonts through:

```javascript
// Font loading and testing
let fontFamilies = [], ffs = [];
content.querySelectorAll('style').forEach(s => {
  fontFamilies = s.innerText.match(/font-family:[^;]*;/gi) || [];
  ffs = fontFamilies.map(v => v.match(/font-family:(.*);/)[1].trim());
});

// Font testing
document.fonts.forEach(f => {
  if (ffs.indexOf(f.family) > -1 && f.status != 'loaded') {
    f.load();
  }
});
```

### Chapter System
- TOC generation
- Chapter page tracking
- Navigation support

### Performance Optimizations
- Font pre-loading
- Asynchronous parsing
- Progressive rendering

## Example Flow
1. Load HTML book content
2. Process all media references
3. Measure content against container
4. Split content into pages
5. Apply styles and formatting
6. Generate final page DOM

[See full implementation in src/script/bookParser.js]
