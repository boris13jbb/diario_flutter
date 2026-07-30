/// Días hacia atrás para el filtro "Recientes".
const int kRecentNotesDays = 7;

/// Filtros de la lista de notas en la barra lateral.
enum DiaryListFilter {
  all,
  favorites,
  recent,
  pinned,
  archived,
  trash,
  reminders,
}

extension DiaryListFilterExtension on DiaryListFilter {
  String get label {
    switch (this) {
      case DiaryListFilter.all:
        return 'Todas';
      case DiaryListFilter.favorites:
        return 'Favoritos';
      case DiaryListFilter.recent:
        return 'Recientes';
      case DiaryListFilter.pinned:
        return 'Fijadas';
      case DiaryListFilter.archived:
        return 'Archivo';
      case DiaryListFilter.trash:
        return 'Papelera';
      case DiaryListFilter.reminders:
        return 'Recordatorios';
    }
  }
}
