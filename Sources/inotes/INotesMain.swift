import Foundation

@main
enum INotesMain {
  static func main() async {
    let code = await CommandRouter().run()
    exit(code)
  }
}
