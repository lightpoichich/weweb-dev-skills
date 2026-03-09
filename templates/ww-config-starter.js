// ww-config.js — Starter template with WeWeb professional patterns
// Replace {{COMPONENT_NAME}} with your component name
// Remove sections you don't need

export default {
  editor: {
    label: { en: '{{COMPONENT_NAME}}' },
    icon: 'fontawesome/regular/star',
    customStylePropertiesOrder: [
      {
        label: 'Layout',
        isCollapsible: true,
        properties: ['containerPadding', 'gap'],
      },
      {
        label: 'Colors',
        isCollapsible: true,
        properties: ['primaryColor', 'backgroundColor'],
      },
    ],
  },

  properties: {
    // ═══════════════════════════════════════════
    // BASIC PROPERTIES
    // ═══════════════════════════════════════════

    title: {
      label: { en: 'Title' },
      type: 'Text',
      section: 'settings',
      bindable: true,
      defaultValue: 'My Component',
      /* wwEditor:start */
      bindingValidation: {
        type: 'string',
        tooltip: 'A text string for the component title',
      },
      propertyHelp: {
        tooltip: 'The main title displayed in the component.',
      },
      /* wwEditor:end */
    },

    showTitle: {
      label: { en: 'Show Title' },
      type: 'OnOff',
      section: 'settings',
      bindable: true,
      defaultValue: true,
      /* wwEditor:start */
      bindingValidation: {
        type: 'boolean',
        tooltip: 'true or false',
      },
      /* wwEditor:end */
    },

    // ═══════════════════════════════════════════
    // TEXTSELECT (correct nested format)
    // ═══════════════════════════════════════════

    theme: {
      label: { en: 'Theme' },
      type: 'TextSelect',
      section: 'settings',
      options: {
        options: [
          { value: 'light', label: 'Light' },
          { value: 'dark', label: 'Dark' },
          { value: 'auto', label: 'Auto' },
        ],
      },
      defaultValue: 'light',
      bindable: true,
      /* wwEditor:start */
      bindingValidation: {
        type: 'string',
        tooltip: 'Valid values: light | dark | auto',
      },
      /* wwEditor:end */
    },

    // ═══════════════════════════════════════════
    // ARRAY WITH OBJECTS (professional standard)
    // ═══════════════════════════════════════════

    items: {
      label: { en: 'Items' },
      type: 'Array',
      section: 'settings',
      bindable: true,
      defaultValue: [
        { id: 'item-1', label: 'First Item', value: '100' },
        { id: 'item-2', label: 'Second Item', value: '200' },
      ],
      options: {
        expandable: true,
        getItemLabel(item) {
          return item?.label || item?.name || item?.title || `Item ${item?.id || 'Unknown'}`;
        },
        item: {
          type: 'Object',
          defaultValue: { id: 'new-item', label: 'New Item', value: '' },
          options: {
            item: {
              id: { label: { en: 'ID' }, type: 'Text' },
              label: { label: { en: 'Label' }, type: 'Text' },
              value: { label: { en: 'Value' }, type: 'Text' },
            },
          },
        },
      },
      /* wwEditor:start */
      bindingValidation: {
        type: 'array',
        tooltip: 'Array of objects: { id, label, value }',
      },
      /* wwEditor:end */
    },

    // Formula mapping for dynamic field binding
    itemsLabelFormula: {
      label: { en: 'Label Field' },
      type: 'Formula',
      section: 'settings',
      options: content => ({
        template:
          Array.isArray(content.items) && content.items.length > 0
            ? content.items[0]
            : null,
      }),
      defaultValue: { type: 'f', code: "context.mapping?.['label']" },
      hidden: (content, _sidepanelContent, boundProps) =>
        !Array.isArray(content.items) ||
        !content.items?.length ||
        !boundProps.items,
    },

    itemsValueFormula: {
      label: { en: 'Value Field' },
      type: 'Formula',
      section: 'settings',
      options: content => ({
        template:
          Array.isArray(content.items) && content.items.length > 0
            ? content.items[0]
            : null,
      }),
      defaultValue: { type: 'f', code: "context.mapping?.['value']" },
      hidden: (content, _sidepanelContent, boundProps) =>
        !Array.isArray(content.items) ||
        !content.items?.length ||
        !boundProps.items,
    },

    // Legacy ObjectPropertyPath (backward compat)
    itemsDisplayPath: {
      label: { en: 'Display Property' },
      type: 'ObjectPropertyPath',
      section: 'settings',
      hidden: content => !content?.items?.length,
      defaultValue: 'label',
      bindable: true,
    },

    // ═══════════════════════════════════════════
    // STYLE PROPERTIES
    // ═══════════════════════════════════════════

    primaryColor: {
      label: { en: 'Primary Color' },
      type: 'Color',
      section: 'style',
      bindable: true,
      responsive: true,
      defaultValue: '#3B82F6',
      /* wwEditor:start */
      bindingValidation: {
        type: 'string',
        tooltip: 'A CSS color value (hex, rgb, hsl)',
      },
      /* wwEditor:end */
    },

    backgroundColor: {
      label: { en: 'Background Color' },
      type: 'Color',
      section: 'style',
      bindable: true,
      responsive: true,
      defaultValue: '#FFFFFF',
    },

    containerPadding: {
      label: { en: 'Padding' },
      type: 'Length',
      section: 'style',
      responsive: true,
      defaultValue: '16px',
    },

    gap: {
      label: { en: 'Gap' },
      type: 'Length',
      section: 'style',
      responsive: true,
      defaultValue: '8px',
    },

    // ═══════════════════════════════════════════
    // INPUT/SELECT COMPONENT (uncomment if needed)
    // ═══════════════════════════════════════════

    // initialValue: {
    //   label: { en: 'Initial value' },
    //   type: 'Text',
    //   section: 'settings',
    //   bindable: true,
    //   defaultValue: '',
    // },

    // --- Form Container Integration (uncomment if input component) ---
    // required: {
    //   label: { en: 'Required' }, type: 'OnOff', section: 'settings',
    //   defaultValue: false, bindable: true,
    //   /* wwEditor:start */
    //   bindingValidation: { type: 'boolean', tooltip: 'true or false' },
    //   propertyHelp: { tooltip: 'Make the field required for form validation.' },
    //   /* wwEditor:end */
    // },
    // /* wwEditor:start */
    // form: { editorOnly: true, hidden: true, defaultValue: false },
    // formInfobox: {
    //   type: 'InfoBox', section: 'settings',
    //   options: (_, sidePanelContent) => ({
    //     variant: sidePanelContent.form?.name ? 'success' : 'warning',
    //     icon: 'pencil',
    //     title: sidePanelContent.form?.name || 'Unnamed form',
    //     content: !sidePanelContent.form?.name && 'Give your form a meaningful name.',
    //     cta: { label: 'Select form', action: 'selectForm' },
    //   }),
    //   hidden: (_, sidePanelContent) => !sidePanelContent.form?.uid,
    // },
    // /* wwEditor:end */
    // fieldName: {
    //   label: { en: 'Field name' }, section: 'settings', type: 'Text',
    //   defaultValue: '', bindable: true,
    //   hidden: (_, sidePanelContent) => !sidePanelContent.form?.uid,
    // },
    // customValidation: {
    //   label: { en: 'Custom validation' }, section: 'settings', type: 'OnOff',
    //   defaultValue: false, bindable: true,
    //   hidden: (_, sidePanelContent) => !sidePanelContent.form?.uid,
    // },
    // validation: {
    //   label: { en: 'Validation' }, section: 'settings', type: 'Formula',
    //   defaultValue: '', bindable: false,
    //   hidden: (content, sidePanelContent) =>
    //     !sidePanelContent.form?.uid || !content?.customValidation,
    // },

    // ═══════════════════════════════════════════
    // DROPZONE (uncomment if needed)
    // ═══════════════════════════════════════════

    // dropzoneContent: { hidden: true, defaultValue: [] },
    // showDropzone: {
    //   label: { en: 'Show Dropzone' }, type: 'OnOff',
    //   section: 'settings', defaultValue: true, bindable: true,
    // },
  },

  triggerEvents: [
    {
      name: 'click',
      label: { en: 'On click' },
      event: { value: '' },
      /* wwEditor:start */
      default: true,
      /* wwEditor:end */
    },
    {
      name: 'value-change',
      label: { en: 'On value change' },
      event: { value: '' },
    },
    // Uncomment for input components:
    // {
    //   name: 'initValueChange',
    //   label: { en: 'On init value change' },
    //   event: { value: '' },
    // },
  ],
}
