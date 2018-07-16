#include    "Text.h"

#pragma once

//-------------------------------------------------------------------------------------------------
class TextLess {
    public:
        bool operator () (const Text& a, const Text& b) const {
            return a < b;
        }
};

//-------------------------------------------------------------------------------------------------
template<typename ValueType>
class TextMap : public map<Text, ValueType, TextLess> {
    public:
        typedef map<Text, ValueType, TextLess> base_container;
        typedef typename base_container::iterator iterator;
        typedef typename base_container::const_iterator const_iterator;

        TextMap<ValueType>& set (const Text& key, const ValueType& value) {
            (*this)[key] = value;
            return *this;
        }

        bool contains (const Text& key) {
            return (this->find (key) != this->end ());
        }

        ValueType* get (const Text& key) {
            iterator find = this->find (key);
            return (find != this->end ()) ? &(find->second) : 0;
        }

        const ValueType* get (const Text& key) const {
            const_iterator find = this->find (key);
            return (find != this->end ()) ? &(find->second) : 0;
        }

        Text toText () const {
            Text result;
            const char* separator = "";
            for (const_iterator it = this->begin (); it != this->end (); ++it) {
                result << separator << (it->first) << ": " << (it->second);
                separator = ", ";
            }
            return result;
        }
};

template<typename ValueType>
ostream& operator << (ostream& ostr, const TextMap<ValueType>& map) {
    return ostr << map.toText();
}

//-------------------------------------------------------------------------------------------------
class TextSet : public set<Text, TextLess> {
    public:
        typedef set<Text, TextLess> base_container;
        typedef typename base_container::iterator iterator;
        typedef typename base_container::const_iterator const_iterator;

        TextSet& put (const Text& value) {
            this->insert (value);
            return *this;
        }

        bool contains (const Text& value) {
            return (this->find (value) != this->end ());
        }

        Text toText () const {
            Text result;
            const char* separator = "";
            for (const_iterator it = this->begin (); it != this->end (); ++it) {
                result << separator << *it;
                separator = ", ";
            }
            return result;
        }
};

inline
ostream& operator << (ostream& ostr, const TextSet& set) {
    return ostr << set.toText();
}

//-------------------------------------------------------------------------------------------------

