export default {
  editor: {
    label: { en: 'Progress Tracker' },
    icon: 'fontawesome/regular/list-check',
    customStylePropertiesOrder: [
      {
        label: 'Appearance',
        isCollapsible: true,
        properties: ['activeColor', 'stepSize'],
      },
    ],
  },

  properties: {
    // ═══════════════════════════════════════════
    // SETTINGS
    // ═══════════════════════════════════════════

    title: {
      label: { en: 'Title' },
      type: 'Text',
      section: 'settings',
      bindable: true,
      defaultValue: 'Progress',
      /* wwEditor:start */
      bindingValidation: {
        type: 'string',
        tooltip: 'A text string for the tracker title',
      },
      propertyHelp: {
        tooltip: 'The heading displayed above the progress steps.',
      },
      /* wwEditor:end */
    },

    showLabels: {
      label: { en: 'Show Labels' },
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

    currentStep: {
      label: { en: 'Current Step' },
      type: 'Number',
      section: 'settings',
      bindable: true,
      defaultValue: 0,
      options: { min: 0, max: 100, step: 1 },
      /* wwEditor:start */
      bindingValidation: {
        type: 'number',
        tooltip: 'The index of the currently active step (0-based)',
      },
      propertyHelp: {
        tooltip: 'Controls which step is currently active. Steps before this index are marked as completed.',
      },
      /* wwEditor:end */
    },

    layout: {
      label: { en: 'Layout' },
      type: 'TextSelect',
      section: 'settings',
      options: {
        options: [
          { value: 'horizontal', label: 'Horizontal' },
          { value: 'vertical', label: 'Vertical' },
          { value: 'compact', label: 'Compact' },
        ],
      },
      defaultValue: 'horizontal',
      bindable: true,
      /* wwEditor:start */
      bindingValidation: {
        type: 'string',
        tooltip: 'horizontal | vertical | compact',
      },
      /* wwEditor:end */
    },

    steps: {
      label: { en: 'Steps' },
      type: 'Array',
      section: 'settings',
      bindable: true,
      defaultValue: [
        { id: 'step-1', label: 'Start', description: 'Get started with the process' },
        { id: 'step-2', label: 'Configure', description: 'Set up your preferences' },
        { id: 'step-3', label: 'Complete', description: 'Finish and review' },
      ],
      options: {
        expandable: true,
        getItemLabel(item) {
          return item?.label || 'Step';
        },
        item: {
          type: 'Object',
          defaultValue: { id: 'new-step', label: 'New Step', description: '' },
          options: {
            item: {
              id: { label: { en: 'ID' }, type: 'Text' },
              label: { label: { en: 'Label' }, type: 'Text' },
              description: { label: { en: 'Description' }, type: 'Text' },
            },
          },
        },
      },
      /* wwEditor:start */
      bindingValidation: {
        type: 'array',
        tooltip: 'Array of objects: { id, label, description }',
      },
      /* wwEditor:end */
    },

    stepsLabelFormula: {
      label: { en: 'Label Field' },
      type: 'Formula',
      section: 'settings',
      options: content => ({
        template:
          Array.isArray(content.steps) && content.steps.length > 0
            ? content.steps[0]
            : null,
      }),
      defaultValue: { type: 'f', code: "context.mapping?.['label']" },
      hidden: (content, _sidepanelContent, boundProps) =>
        !Array.isArray(content.steps) ||
        !content.steps?.length ||
        !boundProps.steps,
    },

    // ═══════════════════════════════════════════
    // STYLE
    // ═══════════════════════════════════════════

    activeColor: {
      label: { en: 'Active Color' },
      type: 'Color',
      section: 'style',
      bindable: true,
      defaultValue: '#3B82F6',
      /* wwEditor:start */
      bindingValidation: {
        type: 'string',
        tooltip: 'A CSS color value (hex, rgb, hsl)',
      },
      /* wwEditor:end */
    },

    stepSize: {
      label: { en: 'Step Size' },
      type: 'Number',
      section: 'style',
      bindable: true,
      defaultValue: 32,
      options: { min: 16, max: 64, step: 4 },
      /* wwEditor:start */
      bindingValidation: {
        type: 'number',
        tooltip: 'Size in pixels for step indicators (16-64)',
      },
      /* wwEditor:end */
    },
  },

  triggerEvents: [
    {
      name: 'step-click',
      label: { en: 'On step click' },
      event: { value: '' },
      /* wwEditor:start */
      default: true,
      /* wwEditor:end */
    },
    {
      name: 'step-complete',
      label: { en: 'On step complete' },
      event: { value: '' },
    },
    {
      name: 'value-change',
      label: { en: 'On value change' },
      event: { value: '' },
    },
  ],
};
