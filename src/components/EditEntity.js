import getWeb3 from '../utils/web3';
import DeviceManager, { getDefaultAccount } from '../DeviceManager';

import React, { Component } from 'react';
import { Card, Input, Button, message, notification } from 'antd';
import { EditOutlined } from '@ant-design/icons';


const { TextArea } = Input;

const openNotificationWithIcon = (type, message, description) => {
  notification[type]({
    message,
    description
  });
};

class EditEntity extends Component {
  constructor(props) {
    super(props);

    this.state = {
      myData: null,
      showEdit: false,
      web3: null,
      instance: null,
      loading: true,
      filter: null
    }

    this.toggleEdit = this.toggleEdit.bind(this);
    this.commonChange = this.commonChange.bind(this);
    this.saveMyData = this.saveMyData.bind(this);
    this.updateMyData = this.updateMyData.bind(this);
    this.watchForChanges = this.watchForChanges.bind(this);
  }

  async componentWillMount() {
    try {
      let defaultAccount = await getDefaultAccount(); 
      let web3 = (await getWeb3).web3;
      let instance = await DeviceManager;
  
      this.setState({
        defaultAccount,
        web3,
        instance
      });
  
      this.updateMyData(); // update the function name here
    } catch (error) {
      console.log(error);
      //message.error(error.message);
      this.setState({
        loading: false,
        showError: true
      })
    }
  }

  async watchForChanges() {
    let filter = this.state.web3.eth.subscribe('newBlockHeaders', async (error, result) => {
      if (!error) {
        openNotificationWithIcon('success', 'Transaction mined', 'Your entity data has been updated.');
        filter.unsubscribe();
        await this.updateMyData();
      } else {
        console.error(error);
      }
    });
  
    this.setState({
      filter
    });
  }

  async updateMyData() {
    try {
      let defaultAccount = await getDefaultAccount();
      let result = await this.state.instance.ownerToEntity(defaultAccount);
      this.setState({
        myData: result,
        myDataNew: result,
        loading: false
      })
    } catch (error) {
      console.log(error);
      message.error(error.message);
    }
  }

  toggleEdit() {
    this.setState(prevState => ({
      showEdit: !prevState.showEdit
    }));
  }

  commonChange(e) {
    this.setState({
      [e.target.name]: e.target.value
    });
  }

  async saveMyData() {
    try {
      if (this.state.myDataNew !== this.state.myData) {
        let instance = await DeviceManager;
        let defaultAccount = await getDefaultAccount();
        await instance.updateEntityData(this.state.myDataNew, { from: defaultAccount });
        this.watchForChanges();
        openNotificationWithIcon('info', 'Transaction sent', 'Once mined, your entity data will be updated.');
        this.setState({
          loading: true,
        });
      }
      this.toggleEdit();
    } catch (error) {
      console.log(error);
      message.error(error.message);
    }
  }

  render() {
    const { defaultAccount } = this.state;
    return (
      <div>
        <p>
          Edit your entity details.
        </p>
        <Card style={{ maxWidth: '500px' }} loading={this.state.loading} title={defaultAccount}>
          {this.state.showEdit ?
            <div>
              <TextArea name="myDataNew" value={this.state.myDataNew} onChange={this.commonChange} />
              <Button type="primary" style={{ marginTop: '10px' }} onClick={this.saveMyData}>Save</Button>
            </div>
            :
            <p>{this.state.myData || <em>empty data</em>} <Button icon={<EditOutlined />} type="primary" onClick={this.toggleEdit}>Edit Entity Data</Button></p>
          }
        </Card>
      </div>
    )
  }
}

export default EditEntity;