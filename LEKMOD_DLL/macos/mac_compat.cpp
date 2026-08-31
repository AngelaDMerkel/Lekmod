#include "CvGameCoreDLLPCH.h"
#include "CvEnumSerialization.h"

namespace {
template <typename EnumType>
FDataStream& WriteEnum(FDataStream& stream, const EnumType& value) {
  stream << static_cast<int>(value);
  return stream;
}

template <typename EnumType>
FDataStream& ReadEnum(FDataStream& stream, EnumType& value) {
  int serialized_value = 0;
  stream >> serialized_value;
  value = static_cast<EnumType>(serialized_value);
  return stream;
}
}  // namespace

FDataStream& operator<<(FDataStream& stream, const ButtonPopupTypes& value) {
  return WriteEnum(stream, value);
}

FDataStream& operator>>(FDataStream& stream, ButtonPopupTypes& value) {
  return ReadEnum(stream, value);
}

FDataStream& operator<<(FDataStream& stream, const DiploUIStateTypes& value) {
  return WriteEnum(stream, value);
}

FDataStream& operator>>(FDataStream& stream, DiploUIStateTypes& value) {
  return ReadEnum(stream, value);
}

FDataStream& operator<<(FDataStream& stream,
                        const LeaderheadAnimationTypes& value) {
  return WriteEnum(stream, value);
}

FDataStream& operator>>(FDataStream& stream,
                        LeaderheadAnimationTypes& value) {
  return ReadEnum(stream, value);
}
