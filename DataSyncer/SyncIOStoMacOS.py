from DataSyncerUtils import replace_directory, get_latest_ios_documents, MACOS_DATA_DATA_PATH, MACOS_DATA_DOCUMENTS_PATH

# Replaces the macOS build's Documents directory with the latest iOS container's Documents directory.
# The old macOS Documents directory is copied to a "Documents Backup" directory within the container.

# 1. Download the iOS build's container.
# 2. Change IOS_DATA_CONTAINER_PATH and MACOS_DATA_DATA_PATH in DataSyncerUtils to the absolute paths of the respective containers.
# 3. Run this script.

DOCUMENTS_BACKUP_DIRECTORY = MACOS_DATA_DATA_PATH + '/Documents Backup'

replace_directory(MACOS_DATA_DOCUMENTS_PATH, DOCUMENTS_BACKUP_DIRECTORY)
replace_directory(get_latest_ios_documents(), MACOS_DATA_DOCUMENTS_PATH)
