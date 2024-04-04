#include <common/boost_utils.hpp>


bool common::boostJsonContains(
    boost::json::object const& obj,
    std::string const& keyName)
{
    return obj.find(keyName) != obj.end();
}


std::string common::boostGetString(
    boost::json::object const& obj,
    std::string const& keyName)
{
    using namespace std::string_literals;

    if (false == common::boostJsonContains(obj, keyName))
    {
        logErr()
            << "object[" << obj << "] doest not contains key[" << keyName << "]";
        return ""s;
    }

    try
    {
        return obj.at(keyName).as_string().c_str();
    }
    catch (boost::exception const& e)
    {
        logErr()
            << "object[" << obj << "] can not get string on key [" << keyName << "]"
            << diagnostic_information(e);
    }

    return ""s;
}
