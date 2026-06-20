#ifndef DATASET_CONFIG_H
#define DATASET_CONFIG_H

enum class DatasetID {
  CryptoTrans,
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
  // random cases for scalability
  Random_N10M_D8,
  INVALID_ID = -1
};

// -----------------------------------------------------------------
// Static Time Data Structure
template<DatasetID dataset>
struct DatasetConfig;

template<>
struct DatasetConfig<DatasetID::Amazon> {
  static constexpr char *DATASET_NAME = "Amazon";
  static constexpr char *PATH_ROW_OFFSETS = "data/realworld_datasets/Amazon/amazon_rowOffsets.txt";
  static constexpr char *PATH_COL_INDICES = "data/realworld_datasets/Amazon/amazon_colIndices.txt";
  // static constexpr size_t  PATH_BUFFER_RATIO = 1000;
  static constexpr size_t PATH_BUFFER_RATIO = 925872 / 334863 * 10;
  static constexpr size_t MATCHING_SIZE = 148485;
};

// template <>
// struct DatasetConfig<DatasetType::CryptoTrans> {
//   static constexpr char* DATASET_NAME = "CryptoTrans";
//   static constexpr char*  PATH_ROW_OFFSETS = "";
//   static constexpr char*  PATH_COL_INDICES= "";
//   static constexpr size_t  PATH_BUFFER_RATIO = 100;
// };

template<>
struct DatasetConfig<DatasetID::HiggsNets> {
  static constexpr char *DATASET_NAME = "HiggsNets";
  static constexpr char *PATH_ROW_OFFSETS = "data/realworld_datasets/HiggsNets/higgsnets_rowOffsets.txt";
  static constexpr char *PATH_COL_INDICES = "data/realworld_datasets/HiggsNets/higgsnets_colIndices.txt";
  // static constexpr size_t  PATH_BUFFER_RATIO = 300;
  static constexpr size_t PATH_BUFFER_RATIO = 12508409 / 456626 * 50;
  static constexpr size_t MATCHING_SIZE = 194919;
};

template<>
struct DatasetConfig<DatasetID::Wikipedia> {
  static constexpr char *DATASET_NAME = "Wikipedia";
  static constexpr char *PATH_ROW_OFFSETS = "data/realworld_datasets/Wikipedia/wiki_rowOffsets.txt";
  static constexpr char *PATH_COL_INDICES = "data/realworld_datasets/Wikipedia/wiki_colIndices.txt";
  // static constexpr size_t PATH_BUFFER_RATIO = 100;
  static constexpr size_t PATH_BUFFER_RATIO = 10 * 4659565 / 2394385;
  static constexpr size_t MATCHING_SIZE = 56063;
};

template<>
struct DatasetConfig<DatasetID::Youtube> {
  static constexpr char *DATASET_NAME = "Youtube";
  static constexpr char *PATH_ROW_OFFSETS = "data/realworld_datasets/Youtube/youtube_rowOffsets.txt";
  static constexpr char *PATH_COL_INDICES = "data/realworld_datasets/Youtube/youtube_colIndices.txt";
  // static constexpr size_t PATH_BUFFER_RATIO = 100;
  static constexpr size_t PATH_BUFFER_RATIO = 2987624 / 1134890 * 10;
  static constexpr size_t MATCHING_SIZE = 274331;
};

template<>
struct DatasetConfig<DatasetID::GPlus> {
  static constexpr char *DATASET_NAME = "GPlus";
  static constexpr char *PATH_ROW_OFFSETS = "data/realworld_datasets/Google/gplus_rowOffsets.txt";
  static constexpr char *PATH_COL_INDICES = "data/realworld_datasets/Google/gplus_columnIndices.txt";
  // static constexpr size_t  PATH_BUFFER_RATIO = 7000;
  static constexpr size_t PATH_BUFFER_RATIO = 12238285 / 107614 * 50;
  static constexpr size_t MATCHING_SIZE = 45753;
};


template<>
struct DatasetConfig<DatasetID::Hyperlink> {
  static constexpr char *DATASET_NAME = "Hyperlink";
  static constexpr char *PATH_ROW_OFFSETS = "data/realworld_datasets/Hyperlink/hyperlink_rowOffsets.txt";
  static constexpr char *PATH_COL_INDICES = "data/realworld_datasets/Hyperlink/hyperlink_colIndices.txt";
  // static constexpr size_t PATH_BUFFER_RATIO = 400;
  static constexpr size_t PATH_BUFFER_RATIO = 25444206 / 1791489 * 30;
  static constexpr size_t MATCHING_SIZE = 756208;
};

template<>
struct DatasetConfig<DatasetID::Livejournal> {
  static constexpr char *DATASET_NAME = "Livejournal";
  static constexpr char *PATH_ROW_OFFSETS = "data/realworld_datasets/LiveJournal/livejournal_rowOffsets.txt";
  static constexpr char *PATH_COL_INDICES = "data/realworld_datasets/LiveJournal/livejournal_colIndices.txt";
  // static constexpr size_t  PATH_BUFFER_RATIO = 150;
  static constexpr size_t PATH_BUFFER_RATIO = 42851237 / 4847571 * 10;
  static constexpr size_t MATCHING_SIZE = 2104653;
};

template<>
struct DatasetConfig<DatasetID::Patent> {
  static constexpr char *DATASET_NAME = "Patent";
  static constexpr char *PATH_ROW_OFFSETS = "data/realworld_datasets/Patent/Patents_rowOffsets.txt";
  static constexpr char *PATH_COL_INDICES = "data/realworld_datasets/Patent/Patents_colIndices.txt";
  // static constexpr size_t  PATH_BUFFER_RATIO = 100;
  static constexpr size_t PATH_BUFFER_RATIO = 16518947 / 3774768 * 30;
  static constexpr size_t MATCHING_SIZE = 1591723;
};

template<>
struct DatasetConfig<DatasetID::Stackoverflow> {
  static constexpr char *DATASET_NAME = "Stackoverflow";
  static constexpr char *PATH_ROW_OFFSETS = "data/realworld_datasets/StackOverflow/stackOverflow_rowOffsets.txt";
  static constexpr char *PATH_COL_INDICES = "data/realworld_datasets/StackOverflow/stackOverflow_columnIndices.txt";
  // static constexpr size_t  PATH_BUFFER_RATIO = 300;
  static constexpr size_t PATH_BUFFER_RATIO = 228183518 / 2601977 * 1;
  static constexpr size_t MATCHING_SIZE = 662500;
};

template<>
struct DatasetConfig<DatasetID::Twitch> {
  static constexpr char *DATASET_NAME = "Twitch";
  static constexpr char *PATH_ROW_OFFSETS = "data/realworld_datasets/Twitch/large_twitch_edges_rowOffsets.txt";
  static constexpr char *PATH_COL_INDICES = "data/realworld_datasets/Twitch/large_twitch_edges_colIndices.txt";
  // static constexpr size_t  PATH_BUFFER_RATIO = 300;
  static constexpr size_t PATH_BUFFER_RATIO = 6797557 / 168114 * 30;
  static constexpr size_t MATCHING_SIZE = 82004;
};

template<>
struct DatasetConfig<DatasetID::Random_N10M_D8> {
  static constexpr char *DATASET_NAME = "Random_N10_MD8";
  static constexpr char *PATH_ROW_OFFSETS = "analysis/data/scalability/degree_8/10m_rowOffsets.txt";
  static constexpr char *PATH_COL_INDICES = "analysis/data/scalability/degree_8/10m_columnIndices.txt";
  static constexpr size_t PATH_BUFFER_RATIO = 10;
  static constexpr size_t MATCHING_SIZE = 5000000;
};

// ------------------------------------------------------------------
// Runtime
static inline DatasetID DatasetNameToID(const std::string &name) {
  DatasetID id;
  if (name == "Amazon") {
    id = DatasetID::Amazon;
  } else if (name == "GPlus") {
    id = DatasetID::GPlus;
  } else if (name == "Hyperlink") {
    id = DatasetID::Hyperlink;
  } else if (name == "Livejournal") {
    id = DatasetID::Livejournal;
  } else if (name == "Patent") {
    id = DatasetID::Patent;
  } else if (name == "Stackoverflow") {
    id = DatasetID::Stackoverflow;
  } else if (name == "Twitch") {
    id = DatasetID::Twitch;
  } else if (name == "HiggsNets") {
    id = DatasetID::HiggsNets;
  } else if (name == "Wikipedia") {
    id = DatasetID::Wikipedia;
  } else if (name == "Youtube") {
    id = DatasetID::Youtube;
  }
  // else if (name == "RandomN10M_D8") {
  //   id = DatasetID::Random_N10M_D8;
  // }
  else {
    id = DatasetID::INVALID_ID;
  }
  return id;
}

/**
 *
 * @tparam F
 * @param dataset_id the runtime value to instantiate a dataset object
 * @param f the lambda function that takes that dataset object as input to execute
 * 1. Instantiate a Dataset based on the dataset_id
 * 2. Run F on this newly instantiated dataset.
 */
template<typename F>
static inline void DispatchFuncOnDataset(DatasetID dataset_id, F f) {
  switch (dataset_id) {
    case DatasetID::GPlus:
      f(DatasetConfig<DatasetID::GPlus>{});
      break;
    case DatasetID::Hyperlink:
      f(DatasetConfig<DatasetID::Hyperlink>{});
      break;
    case DatasetID::Livejournal:
      f(DatasetConfig<DatasetID::Livejournal>{});
      break;
    case DatasetID::Patent:
      f(DatasetConfig<DatasetID::Patent>{});
      break;
    case DatasetID::Stackoverflow:
      f(DatasetConfig<DatasetID::Stackoverflow>{});
      break;
    case DatasetID::Twitch:
      f(DatasetConfig<DatasetID::Twitch>{});
      break;
    case DatasetID::HiggsNets:
      f(DatasetConfig<DatasetID::HiggsNets>{});
      break;
    case DatasetID::Wikipedia:
      f(DatasetConfig<DatasetID::Wikipedia>{});
      break;
    case DatasetID::Youtube:
      f(DatasetConfig<DatasetID::Youtube>{});
      break;
    case DatasetID::Amazon:
      f(DatasetConfig<DatasetID::Amazon>{});
      break;
    case DatasetID::Random_N10M_D8:
      f(DatasetConfig<DatasetID::Random_N10M_D8>{});
      break;

    default:
      throw std::invalid_argument("❌ Unknown or unsupported DatasetID");
  }
}

#endif //DATASET_CONFIG_H
