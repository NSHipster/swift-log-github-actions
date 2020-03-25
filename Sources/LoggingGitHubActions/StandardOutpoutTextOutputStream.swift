struct StandardTextOutputStream: TextOutputStream {
    mutating func write(_ string: String) {
        print(string)
    }
}
