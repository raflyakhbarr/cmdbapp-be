// cmdbapp-be/utils/importStore.js

const previews = new Map();

/**
 * Store preview data for later import
 */
function storePreview(previewId, data) {
  previews.set(previewId, {
    ...data,
    timestamp: Date.now()
  });

  // Clean up old previews (older than 1 hour)
  const oneHourAgo = Date.now() - (60 * 60 * 1000);
  for (const [id, preview] of previews.entries()) {
    if (preview.timestamp < oneHourAgo) {
      previews.delete(id);
    }
  }
}

/**
 * Retrieve preview data
 */
function getPreview(previewId) {
  return previews.get(previewId);
}

module.exports = { storePreview, getPreview };
