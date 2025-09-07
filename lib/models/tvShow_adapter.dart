import 'package:hive/hive.dart';
import 'package:smollan_movie_verse/models/tvShow_models.dart';

class TVShowAdapter extends TypeAdapter<TVShow> {
  @override
  final int typeId = 0;

  @override
  TVShow read(BinaryReader reader) {
    final id = reader.readInt();
    final name = reader.readString();
    final imageUrl = reader.readString();
    final rating = reader.readDouble();
    final genres = (reader.readList() as List<dynamic>).cast<String>();
    final summary = reader.readString();

    return TVShow(
      id: id,
      name: name,
      imageUrl: imageUrl.isNotEmpty ? imageUrl : null, // Handle empty strings
      rating: rating,
      genres: genres,
      summary: summary,
    );
  }

  @override
  void write(BinaryWriter writer, TVShow obj) {
    writer.writeInt(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.imageUrl ?? ''); // Handle null values
    writer.writeDouble(obj.rating);
    writer.writeList(obj.genres);
    writer.writeString(obj.summary);
  }
}