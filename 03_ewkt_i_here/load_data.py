import geopandas as gpd
from sqlalchemy import create_engine, text
import os
from pathlib import Path
from dotenv import load_dotenv

# Wczytaj zmienne z pliku .env do środowiska
load_dotenv()

os.environ['SHAPE_RESTORE_SHX'] = 'YES'

# ==================== KONFIGURACJA Z .ENV ====================
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "5432")
DB_NAME = os.getenv("DB_NAME")


# Ustawienia importu
SCHEMA_NAME = "public"
IF_EXISTS_ACTION = 'replace'  # Opcje: 'fail', 'replace', 'append'
# =============================================================

def find_shapefiles_in_data_directory():
    """Wyszukuje wszystkie pliki .shp w podfolderze 'dane'."""
    # === POCZĄTEK ZMIANY ===
    script_dir = Path(__file__).resolve().parent
    data_dir = script_dir / "dane"  # Tworzymy ścieżkę do podfolderu 'dane'
    # === KONIEC ZMIANY ===

    print(f"📂 Przeszukuję folder: {data_dir}")

    # Sprawdzenie, czy folder 'dane' istnieje
    if not data_dir.is_dir():
        print(f"❌ BŁĄD: Folder '{data_dir}' nie został znaleziony!")
        print("Upewnij się, że obok skryptu istnieje podfolder o nazwie 'dane' z plikami shapefile.")
        return []

    # Wyszukanie plików .shp w folderze 'dane'
    shapefiles = list(data_dir.glob("*.shp"))

    if not shapefiles:
        print(f"🟡 INFO: Nie znaleziono żadnych plików .shp w folderze '{data_dir.name}'.")
    else:
        print("🔍 Znaleziono następujące pliki do zaimportowania:")
        for shp_file in shapefiles:
            print(f"  -> {shp_file.name}")

    return shapefiles

def check_env_vars():
    """Sprawdza, czy kluczowe zmienne środowiskowe są zdefiniowane."""
    if not all([DB_USER, DB_PASSWORD, DB_NAME]):
        print("❌ BŁĄD KRYTYCZNY: Brak kluczowych zmiennych w pliku .env!")
        print("Upewnij się, że zdefiniowałeś DB_USER, DB_PASSWORD oraz DB_NAME.")
        return False
    return True

def import_shapefiles(files_to_import):
    """Łączy się z bazą danych i importuje pliki z podanej listy."""
    print("\n🚀 Rozpoczynam import plików shapefile...")

    try:
        connection_string = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
        engine = create_engine(connection_string)
        with engine.connect():
            print(f"✅ Pomyślnie połączono z bazą '{DB_NAME}' na hoście '{DB_HOST}'.")
    except Exception as e:
        print(f"❌ BŁĄD: Nie udało się połączyć z bazą danych. Sprawdź dane w pliku .env.")
        return

    for file_path in files_to_import:
        try:
            table_name = file_path.stem.lower().replace("-", "_")
            print(f"\nProcessing: {file_path.name} -> do tabeli: '{table_name}'")

            # Sprawdzenie czy tabela istnieje i usunięcie jej
            with engine.connect() as conn:
                check_query = text(f"""
                    SELECT EXISTS (
                        SELECT FROM information_schema.tables
                        WHERE table_schema = :schema
                        AND table_name = :table
                    );
                """)
                result = conn.execute(check_query, {"schema": SCHEMA_NAME, "table": table_name})
                table_exists = result.scalar()

                if table_exists:
                    print(f" -> 🗑️  Tabela '{SCHEMA_NAME}.{table_name}' istnieje - usuwam...")
                    drop_query = text(f'DROP TABLE IF EXISTS "{SCHEMA_NAME}"."{table_name}" CASCADE;')
                    conn.execute(drop_query)
                    conn.commit()
                    print(f" -> ✅ Tabela została usunięta.")

            # Wczytanie pliku shapefile (SHAPE_RESTORE_SHX ustawione globalnie w linii 10)
            gdf = gpd.read_file(file_path)

            print(f" -> Wczytano {len(gdf)} obiektów.")
            print(f" -> Wykryty SRID: {gdf.crs.to_epsg() if gdf.crs else 'Brak'}")

            gdf.to_postgis(
                name=table_name,
                con=engine,
                schema=SCHEMA_NAME,
                if_exists='fail',  # Zmieniamy na 'fail' bo tabela już została usunięta
                index=True,
                # index_label='id'
            )
            print(f" -> ✅ Tabela '{SCHEMA_NAME}.{table_name}' została pomyślnie zaimportowana.")
        except Exception as e:
            print(f"❌ BŁĄD podczas importu pliku '{file_path.name}'.")
            print(f"Szczegóły błędu: {e}")

    print("\n🏁 Wszystkie operacje zostały zakończone.")


if __name__ == "__main__":
    if check_env_vars():
        shapefiles_to_import = find_shapefiles_in_data_directory()
        if shapefiles_to_import:
            import_shapefiles(shapefiles_to_import)
