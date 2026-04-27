// Navigation helper functions for Maestro tests

/**
 * Navigate to tab by icon/label
 */
export function goToTab(tabName: string): Record<string, any> {
  return {
    intents: [
      {
        tapOn: { text: tabName },
      },
    ],
  };
}

/**
 * Go back
 */
export function goBack(): Record<string, any> {
  return {
    intents: [
      {
        tapOn: { id: 'back', optional: true },
      },
      {
        pressKey: { key: 'back' },
      },
    ],
  };
}

/**
 * Swipe up on scrollable element
 */
export function swipeUp(times: number = 1): Record<string, any> {
  const swipes = [];
  for (let i = 0; i < times; i++) {
    swipes.push({ swipe: { direction: 'up' } });
  }
  return { repeat: { times: times, what: { swipe: { direction: 'up' } } } };
}

/**
 * Swipe down on scrollable element
 */
export function swipeDown(times: number = 1): Record<string, any> {
  return { repeat: { times: times, what: { swipe: { direction: 'down' } } } };
}
