#ifndef X_BLOSSOM_GTEST_DEV_H
#define X_BLOSSOM_GTEST_DEV_H

#include "gtest/gtest.h"

// ---------------------------------------------------------------------------
// GTEST_TEST_PUBLIC_
//   Same as GTEST_TEST_, but defines TestBody() as public.
// ---------------------------------------------------------------------------
#define GTEST_TEST_PUBLIC_(test_suite_name, test_name, parent_class, parent_id) \
  static_assert(sizeof(GTEST_STRINGIFY_(test_suite_name)) > 1,                 \
                "test_suite_name must not be empty");                          \
  static_assert(sizeof(GTEST_STRINGIFY_(test_name)) > 1,                       \
                "test_name must not be empty");                                \
  class GTEST_TEST_CLASS_NAME_(test_suite_name, test_name)                     \
      : public parent_class {                                                  \
   public:                                                                     \
    GTEST_TEST_CLASS_NAME_(test_suite_name, test_name)() = default;            \
    ~GTEST_TEST_CLASS_NAME_(test_suite_name, test_name)() override = default;  \
    GTEST_TEST_CLASS_NAME_(test_suite_name, test_name)                         \
    (const GTEST_TEST_CLASS_NAME_(test_suite_name, test_name) &) = delete;     \
    GTEST_TEST_CLASS_NAME_(test_suite_name, test_name) & operator=(            \
        const GTEST_TEST_CLASS_NAME_(test_suite_name,                          \
                                     test_name) &) = delete; /* NOLINT */      \
    GTEST_TEST_CLASS_NAME_(test_suite_name, test_name)                         \
    (GTEST_TEST_CLASS_NAME_(test_suite_name, test_name) &&) noexcept = delete; \
    GTEST_TEST_CLASS_NAME_(test_suite_name, test_name) & operator=(            \
        GTEST_TEST_CLASS_NAME_(test_suite_name,                                \
                               test_name) &&) noexcept = delete; /* NOLINT */  \
                                                                               \
   public: /* 👈 changed from private to public */                             \
    void TestBody() override;                                                  \
    [[maybe_unused]] static ::testing::TestInfo* const test_info_;             \
  };                                                                           \
                                                                               \
  ::testing::TestInfo* const GTEST_TEST_CLASS_NAME_(test_suite_name,           \
                                                    test_name)::test_info_ =   \
      ::testing::internal::MakeAndRegisterTestInfo(                            \
          #test_suite_name, #test_name, nullptr, nullptr,                      \
          ::testing::internal::CodeLocation(__FILE__, __LINE__), (parent_id),  \
          ::testing::internal::SuiteApiResolver<                               \
              parent_class>::GetSetUpCaseOrSuite(__FILE__, __LINE__),          \
          ::testing::internal::SuiteApiResolver<                               \
              parent_class>::GetTearDownCaseOrSuite(__FILE__, __LINE__),       \
          new ::testing::internal::TestFactoryImpl<GTEST_TEST_CLASS_NAME_(     \
              test_suite_name, test_name)>);                                   \
  void GTEST_TEST_CLASS_NAME_(test_suite_name, test_name)::TestBody()

// ---------------------------------------------------------------------------
// TEST_F_PUBLIC
//   Drop-in replacement for TEST_F that exposes TestBody() publicly.
// ---------------------------------------------------------------------------
#define GTEST_TEST_F_PUBLIC(test_fixture, test_name)        \
  GTEST_TEST_PUBLIC_(test_fixture, test_name, test_fixture, \
                     ::testing::internal::GetTypeId<test_fixture>())

#if !(defined(GTEST_DONT_DEFINE_TEST_F_PUBLIC) && GTEST_DONT_DEFINE_TEST_F_PUBLIC)
#define TEST_F_PUBLIC(test_fixture, test_name) GTEST_TEST_F_PUBLIC(test_fixture, test_name)
#endif

#endif //X_BLOSSOM_GTEST_DEV_H