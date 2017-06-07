
def OptionSetBody(access, rawValue):
    return '    ' + access + ' ' + 'typealias RawValue = ' + rawValue + '\n' \
            + '    ' + access + ' var rawValue: ' + rawValue + '\n' \
            + '    ' + access + ' init(rawValue: ' + rawValue + ') {\n' \
            + '        self.rawValue = rawValue\n    }\n'

mutablePointerTypes = ['AnyMutablePointer', 'AnyMutableBufferPointer']
bufferPointerTypes = ['AnyMutableBufferPointer', 'AnyBufferPointer']
constPointerTypes = ['AnyPointer', 'AnyBufferPointer']

def rawOPointer(type):
    if type in bufferPointerTypes:
        if type in mutablePointerTypes:
            return '.mutableRawBuffer'
        return '.rawBuffer'
    return rawPointer(type)

def rawPointer(type):
    if type in mutablePointerTypes:
        if type in bufferPointerTypes:
            return '.mutableRawBuffer.baseAddress'
        return '.mutableRawPointer'
    else:
        return constRawPointer(type)

def constRawPointer(type):
    if type in bufferPointerTypes:
        return '.rawBuffer.baseAddress'
    return '.rawPointer'
