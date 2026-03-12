<template>
  <div class="progress-tracker" :class="[`layout-${props.content?.layout || 'horizontal'}`]" :style="dynamicStyles">
    <div v-if="props.content?.title" class="tracker-title">
      {{ props.content?.title }}
    </div>
    <div class="steps-container">
      <div
        v-for="(step, index) in resolvedSteps"
        :key="step?.id || index"
        class="step"
        :class="{
          'step--completed': index < internalCurrentStep,
          'step--active': index === internalCurrentStep,
          'step--upcoming': index > internalCurrentStep,
        }"
        @click="handleStepClick(index)"
      >
        <div class="step-indicator">
          <span class="step-number">{{ index + 1 }}</span>
        </div>
        <div v-if="props.content?.showLabels" class="step-content">
          <span class="step-label">{{ step?.label || `Step ${index + 1}` }}</span>
          <span v-if="step?.description" class="step-description">{{ step?.description }}</span>
        </div>
        <div v-if="index < resolvedSteps.length - 1" class="step-connector"></div>
      </div>
    </div>
  </div>
</template>

<script>
import { computed, watch } from 'vue';

export default {
  props: {
    uid: { type: String, required: true },
    content: { type: Object, required: true },
    /* wwEditor:start */
    wwEditorState: { type: Object, required: true },
    /* wwEditor:end */
  },
  emits: ['trigger-event'],
  setup(props, { emit }) {
    // Internal variable exposed to bindings panel
    const { value: internalCurrentStep, setValue: setInternalCurrentStep } =
      wwLib.wwVariable.useComponentVariable({
        uid: props.uid,
        name: 'currentStep',
        type: 'number',
        defaultValue: 0,
      });

    // Formula resolution for mapped fields
    const { resolveMappingFormula } = wwLib.wwFormula.useFormula();

    // Resolve steps with formula mapping
    const resolvedSteps = computed(() => {
      return (props.content?.steps || []).map(item => {
        const label = resolveMappingFormula(props.content?.stepsLabelFormula, item) ?? item?.label;
        return { ...item, label };
      });
    });

    // CSS variables for dynamic styling
    const dynamicStyles = computed(() => ({
      '--active-color': props.content?.activeColor || '#3B82F6',
      '--step-size': (props.content?.stepSize || 32) + 'px',
    }));

    // Sync internal variable from prop — avoid infinite loops
    watch(
      () => props.content?.currentStep,
      (v) => {
        if (v !== undefined && v !== internalCurrentStep.value) {
          setInternalCurrentStep(v);
          emit('trigger-event', { name: 'value-change', event: { value: v } });
        }
      },
      { immediate: true }
    );

    // Handle step click
    const handleStepClick = (index) => {
      emit('trigger-event', { name: 'step-click', event: { value: index } });

      if (index <= internalCurrentStep.value + 1) {
        const previousStep = internalCurrentStep.value;
        if (index !== internalCurrentStep.value) {
          setInternalCurrentStep(index);
          emit('trigger-event', { name: 'value-change', event: { value: index } });
        }
        if (index > previousStep) {
          emit('trigger-event', { name: 'step-complete', event: { value: previousStep } });
        }
      }
    };

    /* wwEditor:start */
    const isEditing = computed(() => props.wwEditorState?.isEditing);
    /* wwEditor:end */

    return {
      props,
      resolvedSteps,
      dynamicStyles,
      internalCurrentStep,
      handleStepClick,
      /* wwEditor:start */
      isEditing,
      /* wwEditor:end */
    };
  },
};
</script>

<style scoped lang="scss">
.progress-tracker {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.tracker-title {
  font-weight: 600;
  font-size: 16px;
}

.steps-container {
  display: flex;
  align-items: flex-start;
  gap: 4px;
}

.layout-horizontal .steps-container {
  flex-direction: row;
}

.layout-vertical .steps-container,
.layout-compact .steps-container {
  flex-direction: column;
}

.step {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  flex: 1;
  position: relative;
}

.layout-vertical .step,
.layout-compact .step {
  flex: none;
}

.step-indicator {
  width: var(--step-size);
  height: var(--step-size);
  min-width: var(--step-size);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: calc(var(--step-size) * 0.4);
  font-weight: 600;
  transition: all 0.3s ease;
  background: #e5e7eb;
  color: #6b7280;
}

.step--completed .step-indicator {
  background: var(--active-color);
  color: #ffffff;
}

.step--active .step-indicator {
  background: var(--active-color);
  color: #ffffff;
  box-shadow: 0 0 0 4px color-mix(in srgb, var(--active-color) 25%, transparent);
}

.step-content {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.step-label {
  font-weight: 500;
  font-size: 14px;
  color: #374151;
}

.step--active .step-label {
  color: var(--active-color);
}

.step-description {
  font-size: 12px;
  color: #9ca3af;
}

.step-connector {
  flex: 1;
  height: 2px;
  background: #e5e7eb;
  min-width: 16px;
}

.step--completed + .step .step-connector,
.step--completed .step-connector {
  background: var(--active-color);
}

.layout-vertical .step-connector,
.layout-compact .step-connector {
  width: 2px;
  height: 16px;
  min-width: 2px;
  flex: none;
  margin-left: calc(var(--step-size) / 2 - 1px);
}

.layout-compact .step-content {
  display: none;
}

@media (max-width: 768px) {
  .layout-horizontal .steps-container {
    flex-direction: column;
  }

  .layout-horizontal .step-connector {
    width: 2px;
    height: 16px;
    min-width: 2px;
    flex: none;
    margin-left: calc(var(--step-size) / 2 - 1px);
  }
}
</style>
