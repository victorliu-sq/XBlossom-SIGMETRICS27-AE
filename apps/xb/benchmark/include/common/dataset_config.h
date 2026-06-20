#ifndef DATASET_CONFIG_H
#define DATASET_CONFIG_H

enum class DatasetID {
  GPlus,
  Hyperlink,
  Livejournal,
  Patent,
  Stackoverflow,
  Twitch,
  HiggsNets,
  Wikipedia,
  Youtube,
  Amazon,
  // CryptoTrans,

  // random cases for scalability
  Random_N10M_D8,
};

template <DatasetID dataset>
struct DatasetConfig;

template <>
struct DatasetConfig<DatasetID::Amazon> {
  static constexpr char* DATASET_NAME = "Amazon";
  static constexpr char*  PATH_ROW_OFFSETS = "data/realworld_datasets/Amazon/amazon_rowOffsets.txt";
  static constexpr char*  PATH_COL_INDICES= "data/realworld_datasets/Amazon/amazon_colIndices.txt";
  // static constexpr size_t  PATH_BUFFER_RATIO = 1000;
  static constexpr size_t  PATH_BUFFER_RATIO = 925872 / 334863 * 10;
};

// template <>
// struct DatasetConfig<DatasetType::CryptoTrans> {
//   static constexpr char* DATASET_NAME = "CryptoTrans";
//   static constexpr char*  PATH_ROW_OFFSETS = "";
//   static constexpr char*  PATH_COL_INDICES= "";
//   static constexpr size_t  PATH_BUFFER_RATIO = 100;
// };

template <>
struct DatasetConfig<DatasetID::HiggsNets> {
  static constexpr char* DATASET_NAME = "HiggsNets";
  static constexpr char*  PATH_ROW_OFFSETS = "data/realworld_datasets/HiggsNets/higgsnets_rowOffsets.txt";
  static constexpr char*  PATH_COL_INDICES= "data/realworld_datasets/HiggsNets/higgsnets_colIndices.txt";
  // static constexpr size_t  PATH_BUFFER_RATIO = 300;
  static constexpr size_t  PATH_BUFFER_RATIO = 12508409 / 456626 * 10;
};

template <>
struct DatasetConfig<DatasetID::Wikipedia> {
  static constexpr char* DATASET_NAME = "Wikipedia";
  static constexpr char* PATH_ROW_OFFSETS = "data/realworld_datasets/Wikipedia/wiki_rowOffsets.txt";
  static constexpr char* PATH_COL_INDICES= "data/realworld_datasets/Wikipedia/wiki_colIndices.txt";
  // static constexpr size_t PATH_BUFFER_RATIO = 100;
  static constexpr size_t PATH_BUFFER_RATIO = 10 * 4659565 / 2394385;
};

template <>
struct DatasetConfig<DatasetID::Youtube> {
  static constexpr char* DATASET_NAME = "Youtube";
  static constexpr char* PATH_ROW_OFFSETS = "data/realworld_datasets/Youtube/youtube_rowOffsets.txt";
  static constexpr char* PATH_COL_INDICES= "data/realworld_datasets/Youtube/youtube_colIndices.txt";
  // static constexpr size_t PATH_BUFFER_RATIO = 100;
  static constexpr size_t PATH_BUFFER_RATIO = 2987624 / 1134890 * 10;
};

template <>
struct DatasetConfig<DatasetID::GPlus> {
  static constexpr char* DATASET_NAME = "GPlus";
  static constexpr char*  PATH_ROW_OFFSETS = "data/realworld_datasets/Google/gplus_rowOffsets.txt";
  static constexpr char*  PATH_COL_INDICES= "data/realworld_datasets/Google/gplus_columnIndices.txt";
  // static constexpr size_t  PATH_BUFFER_RATIO = 7000;
  static constexpr size_t  PATH_BUFFER_RATIO = 12238285 / 107614 * 30;
};


template <>
struct DatasetConfig<DatasetID::Hyperlink> {
  static constexpr char* DATASET_NAME = "Hyperlink";
  static constexpr char*  PATH_ROW_OFFSETS = "data/realworld_datasets/Hyperlink/hyperlink_rowOffsets.txt";
  static constexpr char*  PATH_COL_INDICES= "data/realworld_datasets/Hyperlink/hyperlink_colIndices.txt";
  // static constexpr size_t PATH_BUFFER_RATIO = 400;
  static constexpr size_t PATH_BUFFER_RATIO = 25444206 / 1791489 * 10;
};

template <>
struct DatasetConfig<DatasetID::Livejournal> {
  static constexpr char* DATASET_NAME = "Livejournal";
  static constexpr char*  PATH_ROW_OFFSETS = "data/realworld_datasets/LiveJournal/livejournal_rowOffsets.txt";
  static constexpr char*  PATH_COL_INDICES= "data/realworld_datasets/LiveJournal/livejournal_colIndices.txt";
  // static constexpr size_t  PATH_BUFFER_RATIO = 150;
  static constexpr size_t  PATH_BUFFER_RATIO = 42851237 / 4847571 * 10;
};

template <>
struct DatasetConfig<DatasetID::Patent> {
  static constexpr char* DATASET_NAME = "Patent";
  static constexpr char*  PATH_ROW_OFFSETS = "data/realworld_datasets/Patent/Patents_rowOffsets.txt";
  static constexpr char*  PATH_COL_INDICES= "data/realworld_datasets/Patent/Patents_colIndices.txt";
  // static constexpr size_t  PATH_BUFFER_RATIO = 100;
  static constexpr size_t  PATH_BUFFER_RATIO = 16518947 / 3774768 * 10;
};

template <>
struct DatasetConfig<DatasetID::Stackoverflow> {
  static constexpr char* DATASET_NAME = "Stackoverflow";
  static constexpr char*  PATH_ROW_OFFSETS = "data/realworld_datasets/StackOverflow/stackOverflow_rowOffsets.txt";
  static constexpr char*  PATH_COL_INDICES= "data/realworld_datasets/StackOverflow/stackOverflow_columnIndices.txt";
  // static constexpr size_t  PATH_BUFFER_RATIO = 300;
  static constexpr size_t  PATH_BUFFER_RATIO = 228183518 / 2601977 * 1;
};

template <>
struct DatasetConfig<DatasetID::Twitch> {
  static constexpr char* DATASET_NAME = "Twitch";
  static constexpr char*  PATH_ROW_OFFSETS = "data/realworld_datasets/Twitch/large_twitch_edges_rowOffsets.txt";
  static constexpr char*  PATH_COL_INDICES= "data/realworld_datasets/Twitch/large_twitch_edges_colIndices.txt";
  // static constexpr size_t  PATH_BUFFER_RATIO = 300;
  static constexpr size_t  PATH_BUFFER_RATIO = 6797557 / 168114 * 10;
};

template <>
struct DatasetConfig<DatasetID::Random_N10M_D8> {
  static constexpr char* DATASET_NAME = "Random_N10_MD8";
  static constexpr char*  PATH_ROW_OFFSETS = "analysis/data/scalability/degree_8/10m_rowOffsets.txt";
  static constexpr char*  PATH_COL_INDICES= "analysis/data/scalability/degree_8/10m_columnIndices.txt";
  static constexpr size_t  PATH_BUFFER_RATIO = 10;
};

#endif //DATASET_CONFIG_H
