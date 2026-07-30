/// Criterios de ordenación de la lista de notas.
enum DiarySortOrder {
  dateDesc,
  dateAsc,
  titleAsc,
  updatedDesc,
  priorityDesc,
}

extension DiarySortOrderExtension on DiarySortOrder {
  String get label {
    switch (this) {
      case DiarySortOrder.dateDesc:
        return 'Más recientes';
      case DiarySortOrder.dateAsc:
        return 'Más antiguas';
      case DiarySortOrder.titleAsc:
        return 'Título A-Z';
      case DiarySortOrder.updatedDesc:
        return 'Última edición';
      case DiarySortOrder.priorityDesc:
        return 'Prioridad';
    }
  }

  String get shortLabel {
    switch (this) {
      case DiarySortOrder.dateDesc:
        return 'Recientes';
      case DiarySortOrder.dateAsc:
        return 'Antiguas';
      case DiarySortOrder.titleAsc:
        return 'A-Z';
      case DiarySortOrder.updatedDesc:
        return 'Editadas';
      case DiarySortOrder.priorityDesc:
        return 'Prioridad';
    }
  }
}
