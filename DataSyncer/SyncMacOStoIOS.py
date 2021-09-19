from DataSyncerUtils import replace_directory, get_latest_ios_documents, MACOS_DATA_DOCUMENTS_PATH

# Replaces the iOS build's Documents directory with the latest macOS container's Documents directory.

# 1. Download the iOS build's container.
# 2. Change IOS_DATA_CONTAINER_PATH and MACOS_DATA_DATA_PATH in DataSyncerUtils to the absolute paths of the respective containers.
# 3. Run this script.
# 4. Replace the iOS build's container.

replace_directory(MACOS_DATA_DOCUMENTS_PATH, get_latest_ios_documents())
