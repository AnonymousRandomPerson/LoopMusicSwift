import os, shutil

# Absolute path to a directory with iOS data containers. The scripts will use the latest modified container in this directory.
IOS_DATA_CONTAINER_PATH = os.path.join(os.environ['HOME'], 'Documents/Programs/iOS/LoopMusicSwift/Containers')
# Relative path to the documents directory to use for iOS.
IOS_DATA_DOCUMENTS_PATH = 'AppData/Documents'
# Absolute path to the data directory in the macOS build.
MACOS_DATA_DATA_PATH = os.path.join(os.environ['HOME'], 'Library/Containers/LoopMusic.LoopMusicSwift/Data')
# Absolute path to the documents directory in the macOS build.
MACOS_DATA_DOCUMENTS_PATH = os.path.join(MACOS_DATA_DATA_PATH, 'Documents')

def replace_directory(src_path: str, target_path: str):
    shutil.rmtree(target_path, ignore_errors=True)
    shutil.copytree(src_path, target_path)
    print('Replaced', target_path, 'with', src_path)

def get_latest_ios_documents() -> str:
    containers = [container for container in os.listdir(IOS_DATA_CONTAINER_PATH) if container.endswith('.xcappdata')]
    if len(containers) == 0:
        raise RuntimeError('No containers found in ' + IOS_DATA_CONTAINER_PATH)
    containers.sort(key=lambda container : os.path.getmtime(os.path.join(IOS_DATA_CONTAINER_PATH, container)))
    return os.path.join(IOS_DATA_CONTAINER_PATH, containers[-1], IOS_DATA_DOCUMENTS_PATH)
