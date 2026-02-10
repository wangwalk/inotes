import Foundation

public enum TrashFolder {
  private static let knownNames: Set<String> = [
    "Recently Deleted",
    "最近删除", "最近刪除",
    "最近削除した項目",
    "최근 삭제한 항목",
    "Zuletzt gelöscht",
    "Supprimés récemment",
    "Borrados recientemente", "Eliminados recientemente",
    "Apagados Recentemente",
    "Eliminati di recente",
    "Onlangs verwijderd",
    "Недавно удаленные",
    "ลบล่าสุด",
    "محذوفة مؤخرًا",
    "Son Silinenler",
  ]

  public static func isTrashName(_ name: String) -> Bool {
    knownNames.contains(name)
  }
}
