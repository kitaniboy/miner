#include <algo/hash.hpp>
#include <algo/hash_utils.hpp>
#include <common/date.hpp>
#include <common/log/log.hpp>


common::TYPELOG LOGGER_LEVEL { common::TYPELOG::__INFO };


void common::setLogLevel(common::TYPELOG const typeLog)
{
    LOGGER_LEVEL = typeLog;
}


common::Logger::Logger(
    [[maybe_unused]] char const* function,
    [[maybe_unused]] std::size_t line,
    common::TYPELOG tl)
    :
    typeLog(tl)
{
#if defined(__LOG_DEBUG)
    ss
        << common::COLOR_PURPLE
        << "[" << function << "][" << line << "]"
        << common::COLOR_DEFAULT;
#endif

    if (typeLog > LOGGER_LEVEL)
    {
        return;
    }

    if (common::TYPELOG::__CUSTOM != typeLog)
    {
        ss << common::getDate();
    }

    switch (typeLog)
    {
        case common::TYPELOG::__CUSTOM:                   break;
        case common::TYPELOG::__INFO:    ss << "(i) - ";  break;
        case common::TYPELOG::__WARNING: ss << "(w) - ";  break;
        case common::TYPELOG::__ERROR:   ss << "(e) - ";  break;
        case common::TYPELOG::__TRACE:   ss << "(t) - ";  break;
        case common::TYPELOG::__DEBUG:   ss << "(d) - ";  break;
        default:                         ss << "(?) - ";   break;
    }
}


common::Logger::~Logger() noexcept
{
    if (typeLog > LOGGER_LEVEL)
    {
        return;
    }

    common::LogInfo info{};
    info.message.assign(ss.str());
    info.typeLog = typeLog;

    common::Logger::logDisplay.print(info);
}


common::Logger& common::Logger::operator<<(
    bool const value)
{
    if (typeLog > LOGGER_LEVEL)
    {
        return *this;
    }

    ss << std::boolalpha << value << std::noboolalpha;
    return *this;

}

common::Logger& common::Logger::operator<<(
    algo::hash256 const& hash)
{
    if (typeLog > LOGGER_LEVEL)
    {
        return *this;
    }

    ss << algo::toHex(hash, false);
    return *this;
}


common::Logger& common::Logger::operator<<(
    algo::hash512 const& hash)
{
    if (typeLog > LOGGER_LEVEL)
    {
        return *this;
    }

    ss << algo::toHex(hash, false);
    return *this;
}


common::Logger& common::Logger::operator<<(
    algo::hash1024 const& hash)
{
    if (typeLog > LOGGER_LEVEL)
    {
        return *this;
    }

    ss << algo::toHex(hash, false);
    return *this;
}


common::Logger& common::Logger::operator<<(
    algo::hash2048 const& hash)
{
    if (typeLog > LOGGER_LEVEL)
    {
        return *this;
    }

    ss << algo::toHex(hash, false);
    return *this;
}

common::Logger& common::Logger::operator<<(
    std::string const& str)
{
    if (typeLog > LOGGER_LEVEL)
    {
        return *this;
    }

    ss << str.c_str();
    return *this;
}


common::Logger& common::Logger::operator<<(
    stratum::StratumJobInfo const& jobInfo)
{
    if (typeLog > LOGGER_LEVEL)
    {
        return *this;
    }

    ss  << "\n"
        << "================================== JobInfo ==================================\n"
        << "JobID:       " << algo::toHex(jobInfo.jobID) << "\n"
        << "HeaderHash:  " << algo::toHex(jobInfo.headerHash) << "\n"
        << "SeedHash:    " << algo::toHex(jobInfo.seedHash) << "\n"
        << "Boundary:    " << algo::toHex(jobInfo.boundary) << "\n"
        << "Boundary 64: " << jobInfo.boundaryU64 << "\n"
        << "BlockNumber: " << jobInfo.blockNumber << "\n"
        << "Epoch:       " << jobInfo.epoch << "\n"
        << "Period:      " << jobInfo.period << "\n"
        << "StartNonce:  " << jobInfo.startNonce << "\n"
        << "TargetBits:  " << jobInfo.targetBits << "\n"
        << "CleanJob:    " << jobInfo.cleanJob << "\n"
        << "=============================================================================\n";

    return *this;
}
