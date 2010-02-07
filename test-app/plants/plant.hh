#pragma once

#include <string>

class Plant {
public:
    void talk () const;

protected:
    Plant (std::string name);

    std::string m_leaves;

private:
    std::string m_name;
};
