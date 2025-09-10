# Syncfusion Rich Text Editor Style Customization Guide

## Customizing Text Styles

To modify existing styles (Headers, Body text etc.):
1. Override the default CSS classes in your component's SCSS file
2. Key classes to target:
   - `.e-rte-content h1` - Header 1
   - `.e-rte-content h2` - Header 2
   - `.e-rte-content p` - Paragraph/body text

Example:
```scss
// In rich-text-editor.component.scss
.e-rte-content h1 {
  font-family: 'YourCustomFont';
  color: #2a3f5f;
  font-weight: 700;
  margin-bottom: 1.5rem;
}
```

## Adding New Styles

1. Create custom format options using the `formats` property:
```typescript
public formats: object = {
  formats: {
    name: 'CustomStyle',
    tag: 'p',
    class: 'custom-style'
  }
};
```

2. Add the custom style to your toolbar items:
```typescript
public tools: ToolbarSettingsModel = {
  items: [
    // ... other items
    'Formats',
    // ...
  ]
};
```

## Font Customization

1. Add custom fonts to the editor:
```typescript
public fontFamily: object = {
  items: [
    {text: 'Custom Font', value: 'CustomFont, sans-serif'},
    // ... other fonts
  ]
};
```

2. Include the font in your CSS:
```scss
@import url('https://fonts.googleapis.com/css2?family=CustomFont&display=swap');
```

## CSS Class Retention in Exported HTML

Syncfusion RTE preserves CSS classes in exported HTML by default. To ensure proper styling:
1. Define all styles in a global CSS file
2. Make sure styles are scoped to `.e-rte-content`
3. Include the same CSS file where the exported HTML will be rendered

## Best Practices
- Keep all RTE styles in a single SCSS file for maintainability
- Use semantic class names that describe the content purpose
- Test exported HTML in all target environments
- Consider creating a style guide document for consistency

## References
- [Syncfusion RTE Formatting Documentation](https://ej2.syncfusion.com/angular/documentation/rich-text-editor/formats/)
- [Syncfusion RTE Toolbar Customization](https://ej2.syncfusion.com/angular/documentation/rich-text-editor/toolbar/)
